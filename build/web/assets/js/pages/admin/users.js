(function () {
        const viewModalElement = document.getElementById('viewAccountModal');
        const viewModal = new bootstrap.Modal(viewModalElement);
        const actionConfirmModalElement = document.getElementById('actionConfirmModal');
        const actionConfirmModal = new bootstrap.Modal(actionConfirmModalElement);
        const actionConfirmTitle = document.getElementById('actionConfirmTitle');
        const actionConfirmMessage = document.getElementById('actionConfirmMessage');
        const actionConfirmSubmitBtn = document.getElementById('actionConfirmSubmitBtn');
        const modalElement = document.getElementById('editAccountModal');
        const modal = new bootstrap.Modal(modalElement);
        const changePasswordModalElement = document.getElementById('changePasswordModal');
        const changePasswordModal = new bootstrap.Modal(changePasswordModalElement);
        const pwdAccountId = document.getElementById('pwdAccountId');
        const pwdAccountName = document.getElementById('pwdAccountName');
        const newPasswordInput = document.getElementById('newPassword');
        const basePath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
        let pendingConfirmForm = null;

        const departmentTextMap = {
            Endocrinology: 'Nội tiết - Tiểu đường',
            Cardiology: 'Tim mạch',
            Nephrology: 'Thận học',
            General: 'Tổng quát'
        };

        function roleText(role) {
            const roleTextMap = {
                Patient: 'Bệnh nhân',
                Doctor: 'Bác sĩ',
                Receptionist: 'Lễ tân',
                Admin: 'Quản trị viên'
            };
            return roleTextMap[role] || role || 'Không xác định';
        }

        const viewFields = {
            roleInfo: document.getElementById('viewRoleInfo'),
            fullName: document.getElementById('viewFullName'),
            email: document.getElementById('viewEmail'),
            phone: document.getElementById('viewPhone'),
            address: document.getElementById('viewAddress'),
            department: document.getElementById('viewDepartment'),
            phoneWrap: document.getElementById('viewPhoneWrap'),
            addressWrap: document.getElementById('viewAddressWrap'),
            departmentWrap: document.getElementById('viewDepartmentWrap')
        };

        const fields = {
            accountId: document.getElementById('editAccountId'),
            fullName: document.getElementById('editFullName'),
            email: document.getElementById('editEmail'),
            phone: document.getElementById('editPhone'),
            address: document.getElementById('editAddress'),
            department: document.getElementById('editDepartment'),
            roleInfo: document.getElementById('editRoleInfo'),
            phoneWrap: document.getElementById('editPhoneWrap'),
            addressWrap: document.getElementById('editAddressWrap'),
            departmentWrap: document.getElementById('editDepartmentWrap')
        };

        function setRoleDisplay(role) {
            fields.roleInfo.textContent = 'Vai trò: ' + roleText(role);

            const isPatient = role === 'Patient';
            const isDoctor = role === 'Doctor';

            fields.phoneWrap.classList.toggle('d-none', !(isPatient || isDoctor));
            fields.addressWrap.classList.toggle('d-none', !isPatient);
            fields.departmentWrap.classList.toggle('d-none', !isDoctor);
            fields.department.required = isDoctor;
        }

        function fillViewProfile(item) {
            const role = item.role || '';
            const isPatient = role === 'Patient';
            const isDoctor = role === 'Doctor';

            viewFields.roleInfo.textContent = 'Vai trò: ' + roleText(role);
            viewFields.fullName.textContent = item.fullName || '-';
            viewFields.email.textContent = item.email || '-';
            viewFields.phone.textContent = item.phone || '-';
            viewFields.address.textContent = item.address || '-';
            viewFields.department.textContent = departmentTextMap[item.department] || item.department || '-';

            viewFields.phoneWrap.classList.toggle('d-none', !(isPatient || isDoctor));
            viewFields.addressWrap.classList.toggle('d-none', !isPatient);
            viewFields.departmentWrap.classList.toggle('d-none', !isDoctor);
        }

        async function fetchAccountProfile(accountId) {
            const url = basePath + '/admin?action=getAccountProfile&accountId=' + encodeURIComponent(accountId);
            const response = await fetch(url, {headers: {'Accept': 'application/json'}});
            if (!response.ok) {
                throw new Error('HTTP ' + response.status);
            }
            const payload = await response.json();
            if (!payload.success || !payload.item) {
                throw new Error(payload.message || 'Không tải được hồ sơ');
            }

            return payload.item;
        }

        async function openEditModal(accountId) {
            const item = await fetchAccountProfile(accountId);

            fields.accountId.value = item.accountId || '';
            fields.fullName.value = item.fullName || '';
            fields.email.value = item.email || '';
            fields.phone.value = item.phone || '';
            fields.address.value = item.address || '';
            fields.department.value = item.department || 'General';
            setRoleDisplay(item.role || '');

            modal.show();
        }

        async function openViewModal(accountId) {
            const item = await fetchAccountProfile(accountId);
            fillViewProfile(item);
            viewModal.show();
        }

        document.addEventListener('click', function (event) {
            const button = event.target.closest('.edit-account-btn');
            if (button) {
                const accountId = button.getAttribute('data-account-id');
                if (!accountId) {
                    return;
                }
                openEditModal(accountId).catch(function (err) {
                    alert('Không thể tải hồ sơ tài khoản. ' + err.message);
                });
                return;
            }

            const changePwdBtn = event.target.closest('.change-password-btn');
            if (changePwdBtn) {
                const accountId = changePwdBtn.getAttribute('data-account-id');
                const accountName = changePwdBtn.getAttribute('data-account-name');
                if (pwdAccountId && pwdAccountName && newPasswordInput) {
                    pwdAccountId.value = accountId || '';
                    pwdAccountName.textContent = accountName || '-';
                    newPasswordInput.value = '';
                    changePasswordModal.show();
                }
                return;
            }

            const row = event.target.closest('tr.account-row');
            if (!row) {
                return;
            }
            if (event.target.closest('button, a, input, select, textarea, label, form')) {
                return;
            }

            const accountId = row.getAttribute('data-account-id');
            if (!accountId) {
                return;
            }

            openViewModal(accountId).catch(function (err) {
                alert('Không thể tải thông tin tài khoản. ' + err.message);
            });
        });

        document.addEventListener('submit', function (event) {
            const form = event.target.closest('form');
            if (!form) {
                return;
            }

            if (form.classList.contains('confirm-action-form')) {
                event.preventDefault();

                pendingConfirmForm = form;
                const actionField = form.querySelector('input[name="action"]');
                const actionValue = actionField ? actionField.value : '';
                const submitBtn = form.querySelector('button[type="submit"]');
                const submitLabel = submitBtn ? submitBtn.textContent.trim() : '';
                const row = form.closest('tr.account-row');
                const nameCell = row ? row.querySelector('td:nth-child(2)') : null;
                const accountName = nameCell ? nameCell.textContent.trim() : 'tài khoản này';

                let title = 'Xác nhận thao tác';
                let message = form.getAttribute('data-confirm-message') || 'Bạn có chắc muốn tiếp tục?';

                if (actionValue === 'deleteAccount') {
                    title = 'Xác nhận xóa';
                    message = 'Bạn có chắc muốn xóa tài khoản "' + accountName + '"? Hành động không thể hoàn tác.';
                } else if (actionValue === 'lockAccount' && submitLabel === 'Vô hiệu hóa') {
                    title = 'Xác nhận vô hiệu hóa';
                    message = 'Bạn có chắc muốn vô hiệu hóa tài khoản bác sĩ "' + accountName + '"?';
                } else if (actionValue === 'lockAccount') {
                    title = 'Xác nhận khóa';
                    message = 'Bạn có chắc muốn khóa tài khoản "' + accountName + '"?';
                }

                actionConfirmTitle.textContent = title;
                actionConfirmMessage.textContent = message;
                actionConfirmSubmitBtn.classList.remove('btn-danger', 'btn-warning');
                actionConfirmSubmitBtn.classList.add(actionValue === 'deleteAccount' ? 'btn-danger' : 'btn-warning');
                actionConfirmModal.show();
                return;
            }
        });

        actionConfirmSubmitBtn.addEventListener('click', function () {
            if (!pendingConfirmForm) {
                actionConfirmModal.hide();
                return;
            }

            const submittingForm = pendingConfirmForm;
            pendingConfirmForm = null;
            actionConfirmModal.hide();
            HTMLFormElement.prototype.submit.call(submittingForm);
        });

        actionConfirmModalElement.addEventListener('hidden.bs.modal', function () {
            if (pendingConfirmForm) {
                pendingConfirmForm = null;
            }
        });

        document.addEventListener('keydown', function (event) {
            if (event.key !== 'Enter') {
                return;
            }
            if (!pendingConfirmForm) {
                return;
            }
            if (!actionConfirmModalElement.classList.contains('show')) {
                return;
            }
            event.preventDefault();
            actionConfirmSubmitBtn.click();
        });
    })();