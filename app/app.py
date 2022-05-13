"""
Sistema de Inventario para Negocio Pequeño
Aplicación Flask con Cloud Storage y Cloud SQL (MySQL)
"""
import os
import io
from flask import Flask, render_template, request, redirect, url_for, jsonify, flash
from google.cloud import storage
import mysql.connector
from datetime import datetime
import uuid

app = Flask(__name__)
app.secret_key = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')

# Configuración de Cloud Storage
BUCKET_NAME = os.environ.get('GCS_BUCKET_NAME', 'inventory-images')
storage_client = storage.Client()

# Configuración de Cloud SQL
def get_db_connection():
    """Crea conexión a Cloud SQL MySQL"""
    connection = mysql.connector.connect(
        host=os.environ.get('DB_HOST', '127.0.0.1'),
        user=os.environ.get('DB_USER', 'root'),
        password=os.environ.get('DB_PASSWORD', ''),
        database=os.environ.get('DB_NAME', 'inventory'),
        port=int(os.environ.get('DB_PORT', 3306))
    )
    return connection

def init_db():
    """Inicializa la base de datos con las tablas necesarias"""
    conn = get_db_connection()
    cursor = conn.cursor()
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS products (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(255) NOT NULL,
            description TEXT,
            sku VARCHAR(100) UNIQUE NOT NULL,
            quantity INT NOT NULL DEFAULT 0,
            price DECIMAL(10, 2) NOT NULL,
            category VARCHAR(100),
            image_url VARCHAR(500),
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        )
    ''')
    
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS inventory_transactions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            product_id INT NOT NULL,
            transaction_type ENUM('IN', 'OUT') NOT NULL,
            quantity INT NOT NULL,
            notes TEXT,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (product_id) REFERENCES products(id)
        )
    ''')
    
    conn.commit()
    cursor.close()
    conn.close()

@app.route('/')
def index():
    """Página principal - lista de productos"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute('''
        SELECT id, name, sku, quantity, price, category, image_url 
        FROM products 
        ORDER BY name
    ''')
    products = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('index.html', products=products)

@app.route('/product/<int:product_id>')
def product_detail(product_id):
    """Detalle de un producto"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute('SELECT * FROM products WHERE id = %s', (product_id,))
    product = cursor.fetchone()
    
    if not product:
        flash('Producto no encontrado', 'error')
        return redirect(url_for('index'))
    
    cursor.execute('''
        SELECT transaction_type, quantity, notes, created_at 
        FROM inventory_transactions 
        WHERE product_id = %s 
        ORDER BY created_at DESC 
        LIMIT 10
    ''', (product_id,))
    transactions = cursor.fetchall()
    
    cursor.close()
    conn.close()
    
    return render_template('product_detail.html', product=product, transactions=transactions)

@app.route('/product/add', methods=['GET', 'POST'])
def add_product():
    """Agregar nuevo producto"""
    if request.method == 'POST':
        name = request.form.get('name')
        description = request.form.get('description')
        sku = request.form.get('sku')
        quantity = int(request.form.get('quantity', 0))
        price = float(request.form.get('price', 0))
        category = request.form.get('category')
        
        image_url = None
        if 'image' in request.files:
            file = request.files['image']
            if file.filename:
                image_url = upload_to_gcs(file)
        
        conn = get_db_connection()
        cursor = conn.cursor()
        
        try:
            cursor.execute('''
                INSERT INTO products (name, description, sku, quantity, price, category, image_url)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            ''', (name, description, sku, quantity, price, category, image_url))
            
            product_id = cursor.lastrowid
            
            if quantity > 0:
                cursor.execute('''
                    INSERT INTO inventory_transactions (product_id, transaction_type, quantity, notes)
                    VALUES (%s, 'IN', %s, 'Inventario inicial')
                ''', (product_id, quantity))
            
            conn.commit()
            flash(f'Producto {name} agregado exitosamente', 'success')
            return redirect(url_for('index'))
        
        except mysql.connector.Error as e:
            conn.rollback()
            flash(f'Error al agregar producto: {str(e)}', 'error')
        
        finally:
            cursor.close()
            conn.close()
    
    return render_template('add_product.html')

@app.route('/product/<int:product_id>/update', methods=['POST'])
def update_inventory(product_id):
    """Actualizar inventario (entrada/salida)"""
    transaction_type = request.form.get('type')
    quantity = int(request.form.get('quantity', 0))
    notes = request.form.get('notes', '')
    
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        if transaction_type == 'IN':
            cursor.execute(
                'UPDATE products SET quantity = quantity + %s WHERE id = %s',
                (quantity, product_id)
            )
        else:
            cursor.execute(
                'UPDATE products SET quantity = quantity - %s WHERE id = %s',
                (quantity, product_id)
            )
        
        cursor.execute('''
            INSERT INTO inventory_transactions (product_id, transaction_type, quantity, notes)
            VALUES (%s, %s, %s, %s)
        ''', (product_id, transaction_type, quantity, notes))
        
        conn.commit()
        flash('Inventario actualizado exitosamente', 'success')
    
    except mysql.connector.Error as e:
        conn.rollback()
        flash(f'Error al actualizar inventario: {str(e)}', 'error')
    
    finally:
        cursor.close()
        conn.close()
    
    return redirect(url_for('product_detail', product_id=product_id))

@app.route('/api/stats')
def api_stats():
    """API endpoint para estadísticas"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute('SELECT COUNT(*) as total_products FROM products')
    total_products = cursor.fetchone()['total_products']
    
    cursor.execute('SELECT SUM(quantity) as total_items FROM products')
    total_items = cursor.fetchone()['total_items'] or 0
    
    cursor.execute('SELECT SUM(quantity * price) as total_value FROM products')
    total_value = cursor.fetchone()['total_value'] or 0
    
    cursor.execute('SELECT COUNT(*) as low_stock FROM products WHERE quantity < 10')
    low_stock = cursor.fetchone()['low_stock']
    
    cursor.close()
    conn.close()
    
    return jsonify({
        'total_products': total_products,
        'total_items': int(total_items),
        'total_value': float(total_value),
        'low_stock': low_stock
    })

def upload_to_gcs(file):
    """Sube archivo a Google Cloud Storage"""
    try:
        bucket = storage_client.bucket(BUCKET_NAME)
        filename = f"{uuid.uuid4()}_{file.filename}"
        blob = bucket.blob(f"products/{filename}")
        
        blob.upload_from_file(file, content_type=file.content_type)
        blob.make_public()
        
        return blob.public_url
    except Exception as e:
        print(f"Error uploading to GCS: {e}")
        return None

@app.route('/health')
def health():
    """Health check endpoint"""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        cursor.execute('SELECT 1')
        cursor.close()
        conn.close()
        return jsonify({'status': 'healthy', 'database': 'connected'}), 200
    except Exception as e:
        return jsonify({'status': 'unhealthy', 'error': str(e)}), 500

if __name__ == '__main__':
    init_db()
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
