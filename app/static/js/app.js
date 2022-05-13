// Cargar estadísticas
document.addEventListener('DOMContentLoaded', function() {
    fetch('/api/stats')
        .then(response => response.json())
        .then(data => {
            document.getElementById('total-products').textContent = data.total_products;
            document.getElementById('total-items').textContent = data.total_items;
            document.getElementById('total-value').textContent = '$' + data.total_value.toFixed(2);
            document.getElementById('low-stock').textContent = data.low_stock;
        })
        .catch(error => console.error('Error loading stats:', error));
});
