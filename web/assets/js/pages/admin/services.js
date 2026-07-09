document.querySelectorAll('.btn-edit-service').forEach((button) => {
        button.addEventListener('click', () => {
            document.getElementById('editServiceId').value = button.dataset.serviceId || '';
            document.getElementById('editServiceName').value = button.dataset.serviceName || '';
            document.getElementById('editServiceType').value = button.dataset.serviceType || 'Examination';
            document.getElementById('editServicePrice').value = button.dataset.price || 0;
            document.getElementById('editServiceStatus').value = button.dataset.status || 'Active';
        });
    });