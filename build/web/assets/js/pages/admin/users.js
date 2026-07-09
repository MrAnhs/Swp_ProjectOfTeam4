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
        const basePath = window.AdminConfig && window.AdminConfig.contextPath ? window.AdminConfig.contextPath : '';
        let pendingConfirmForm = null;

        const departmentTextMap = {
            Endocrinology: 'N\u1ED9i ti\u1EBFt - Ti\u1EC3u \u0111\u01B0\u1EDDng',
            Cardiology: 'Tim m\u1EA1ch',
            Nephrology: 'Th\u1EADn h\u1ECDc',
            General: 'T\u1ED5ng qu\u00E1t'
        };

        function roleText(role) {
            const roleTextMap = {
                Patient: 'B\u1EC7nh nh\u00E2n',
                Doctor: 'B\u00E1c s\u0129',
                Receptionist: 'L\u1EC5 t\u00E2n',
                Admin: 'Qu\u1EA3n tr\u1ECB vi\u00EAn'
            };
            return roleTextMap[role] || role || 'Kh\u00F4ng x\u00E1c \u0111\u1ECBnh';
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
            fields.roleInfo.textContent = 'Vai tr\u00F2: ' + roleText(role);

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

            viewFields.roleInfo.textContent = 'Vai tr\u00F2: ' + roleText(role);
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
                throw new Error(payload.message || 'Kh\u00F4ng t\u1EA3i \u0111\u01B0\u1EE3c h\u1ED3 s\u01A1');
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
                    alert('Kh\u00F4ng th\u1EC3 t\u1EA3i h\u1ED3 s\u01A1 t\u00E0i kho\u1EA3n. ' + err.message);
                });
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
                alert('Kh\u00F4ng th\u1EC3 t\u1EA3i th\u00F4ng tin t\u00E0i kho\u1EA3n. ' + err.message);
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
                const accountName = nameCell ? nameCell.textContent.trim() : 't\u00E0i kho\u1EA3n n\u00E0y';

                let title = 'X\u00E1c nh\u1EADn thao t\u00E1c';
                let message = form.getAttribute('data-confirm-message') || 'B\u1EA1n c\u00F3 ch\u1EAFc mu\u1ED1n ti\u1EBFp t\u1EE5c?';

                if (actionValue === 'deleteAccount') {
                    title = 'X\u00E1c nh\u1EADn x\u00F3a';
                    message = 'B\u1EA1n c\u00F3 ch\u1EAFc mu\u1ED1n x\u00F3a t\u00E0i kho\u1EA3n "' + accountName + '"? H\u00E0nh \u0111\u1ED9ng kh\u00F4ng th\u1EC3 ho\u00E0n t\u00E1c.';
                } else if (actionValue === 'lockAccount' && submitLabel === 'V\u00F4 hi\u1EC7u h\u00F3a') {
                    title = 'X\u00E1c nh\u1EADn v\u00F4 hi\u1EC7u h\u00F3a';
                    message = 'B\u1EA1n c\u00F3 ch\u1EAFc mu\u1ED1n v\u00F4 hi\u1EC7u h\u00F3a t\u00E0i kho\u1EA3n b\u00E1c s\u0129 "' + accountName + '"?';
                } else if (actionValue === 'lockAccount') {
                    title = 'X\u00E1c nh\u1EADn kh\u00F3a';
                    message = 'B\u1EA1n c\u00F3 ch\u1EAFc mu\u1ED1n kh\u00F3a t\u00E0i kho\u1EA3n "' + accountName + '"?';
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