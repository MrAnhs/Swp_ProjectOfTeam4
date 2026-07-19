package com.diabetes.monitoring.admin.management;

import com.diabetes.monitoring.model.User;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Provides account and medical service management use cases.
 */
public class AdminManagementService {
    private final AdminMedicalServiceService medicalServiceService =
            new AdminMedicalServiceService();

    public List<User> loadAccounts(String search, String role, String status, int page, int pageSize) {
        return new AdminAccountService().loadAccounts(search, role, status, page, pageSize);
    }
    public List<User> loadAccounts(String search, String role, String status, int page, int pageSize, User currentUser) {
        return loadAccounts(search, role, status, page, pageSize);
    }

    public int getAccountsTotalCount(String search, String role, String status) {
        return new AdminAccountService().getAccountsTotalCount(search, role, status);
    }
    public int getAccountsTotalCount(String search, String role, String status, User currentUser) {
        return getAccountsTotalCount(search, role, status);
    }

    public boolean isAccountEmailExists(String email) {
        return new AdminAccountService().isAccountEmailExists(email);
    }
    public boolean isAccountEmailExists(String email, User currentUser) {
        return isAccountEmailExists(email);
    }

    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) {
        return new AdminAccountService().createAccount(fullName, email, passwordHash, role, status);
    }
    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status, User currentUser) {
        return createAccount(fullName, email, passwordHash, role, status);
    }

    public boolean updateAccountRole(int accountId, String role) {
        return new AdminAccountService().updateAccountRole(accountId, role);
    }
    public boolean updateAccountRole(int accountId, String role, User currentUser) {
        return updateAccountRole(accountId, role);
    }

    public boolean updateAccountStatus(int accountId, String status) {
        return new AdminAccountService().updateAccountStatus(accountId, status);
    }
    public boolean updateAccountStatus(int accountId, String status, User currentUser) {
        return updateAccountStatus(accountId, status);
    }

    public boolean deleteAccount(int accountId) {
        return new AdminAccountService().deleteAccount(accountId);
    }
    public boolean deleteAccount(int accountId, User currentUser) {
        return deleteAccount(accountId);
    }

    public Map<String, Object> getAccountProfile(int accountId) {
        return new AdminAccountService().getAccountProfile(accountId);
    }
    public Map<String, Object> getAccountProfile(int accountId, User currentUser) {
        return getAccountProfile(accountId);
    }

    public boolean updateAccountProfileByRole(int accountId, String fullName, String email, String phone, String address, String department) {
        return new AdminAccountService().updateAccountProfileByRole(accountId, fullName, email, phone, address, department);
    }
    public boolean updateAccountProfileByRole(int accountId, String fullName, String email, String phone, String address, String department, User currentUser) {
        return updateAccountProfileByRole(accountId, fullName, email, phone, address, department);
    }

    public boolean updateAccountPassword(int accountId, String rawPassword) {
        return new AdminAccountService().updateAccountPassword(accountId, rawPassword);
    }
    public boolean updateAccountPassword(int accountId, String rawPassword, User currentUser) {
        return updateAccountPassword(accountId, rawPassword);
    }

    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) {
        return new AdminAccountService().getStaffAccountsQuick(status, limit);
    }
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit, User currentUser) {
        return getStaffAccountsQuick(status, limit);
    }

    public List<Map<String, Object>> loadServices(String search, String serviceType, String status, int page, int pageSize) {
        return medicalServiceService.loadServices(search, serviceType, status, page, pageSize);
    }
    public List<Map<String, Object>> loadServices(String search, String serviceType, String status, int page, int pageSize, User currentUser) {
        return loadServices(search, serviceType, status, page, pageSize);
    }

    public int getMedicalServicesCount(String search, String serviceType, String status) {
        return medicalServiceService.getMedicalServicesCount(search, serviceType, status);
    }
    public int getMedicalServicesCount(String search, String serviceType, String status, User currentUser) {
        return getMedicalServicesCount(search, serviceType, status);
    }

    public boolean createService(String serviceName, BigDecimal price, String serviceType, String status) {
        return medicalServiceService.createService(serviceName, price, serviceType, status);
    }
    public boolean createService(String serviceName, BigDecimal price, String serviceType, String status, User currentUser) {
        return createService(serviceName, price, serviceType, status);
    }

    public boolean updateService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status) {
        return medicalServiceService.updateService(serviceId, serviceName, price, serviceType, status);
    }
    public boolean updateService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status, User currentUser) {
        return updateService(serviceId, serviceName, price, serviceType, status);
    }

    public boolean deleteService(int serviceId) {
        return medicalServiceService.deleteService(serviceId);
    }
    public boolean deleteService(int serviceId, User currentUser) {
        return deleteService(serviceId);
    }

    public boolean updateServiceStatus(int serviceId, String status) {
        return medicalServiceService.updateServiceStatus(serviceId, status);
    }
    public boolean updateServiceStatus(int serviceId, String status, User currentUser) {
        return updateServiceStatus(serviceId, status);
    }

    public int getCountTotalServices() {
        return medicalServiceService.getTotalServices();
    }
}

/**
 * Applies business rules for account management.
 */
class AdminAccountService {
    private final AdminAccountRepository accountRepository =
            new AdminAccountRepository();

    private void validateAccountInput(String fullName, String email, String phone) {
        if (fullName == null || fullName.trim().isEmpty() || fullName.trim().length() < 2 || fullName.trim().length() > 100) {
            throw new IllegalArgumentException("Họ và tên phải từ 2 đến 100 ký tự.");
        }
        if (email == null || !email.trim().matches("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}$")) {
            throw new IllegalArgumentException("Định dạng email không hợp lệ.");
        }
        if (phone != null && !phone.trim().isEmpty() && !phone.trim().matches("^0\\d{9,10}$")) {
            throw new IllegalArgumentException("Số điện thoại không hợp lệ (phải bắt đầu bằng số 0 và có 10-11 chữ số).");
        }
    }

    public List<User> loadAccounts(String search, String role, String status, int page, int pageSize) {
        return accountRepository.getAccounts(search, role, status, page, pageSize);
    }

    public int getAccountsTotalCount(String search, String role, String status) {
        return accountRepository.getAccountsTotalCount(search, role, status);
    }

    public boolean isAccountEmailExists(String email) {
        return accountRepository.isAccountEmailExists(email);
    }

    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) {
        validateAccountInput(fullName, email, null);
        if (isAccountEmailExists(email)) {
            throw new IllegalArgumentException("Email đã tồn tại, không thể tạo tài khoản trùng.");
        }
        return accountRepository.createAccount(fullName, email, passwordHash, role, status);
    }

    public boolean updateAccountRole(int accountId, String role) {
        return accountRepository.updateAccountRole(accountId, role);
    }

    public boolean updateAccountStatus(int accountId, String status) {
        return accountRepository.updateAccountStatus(accountId, status);
    }

    public boolean deleteAccount(int accountId) {
        return accountRepository.deleteAccountForAdmin(accountId);
    }

    public Map<String, Object> getAccountProfile(int accountId) {
        return accountRepository.getAccountProfileForAdminEdit(accountId);
    }

    public boolean updateAccountProfileByRole(int accountId, String fullName, String email, String phone, String address, String department) {
        validateAccountInput(fullName, email, phone);
        return accountRepository.updateAccountProfileByRole(accountId, fullName, email, phone, address, department);
    }

    public boolean updateAccountPassword(int accountId, String rawPassword) {
        if (rawPassword == null || rawPassword.trim().length() < 6 || rawPassword.trim().length() > 50) {
            throw new IllegalArgumentException("Mật khẩu phải từ 6 đến 50 ký tự.");
        }
        return accountRepository.updateAccountPassword(accountId, rawPassword);
    }

    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) {
        return accountRepository.getStaffAccountsQuick(status, limit);
    }
}

/**
 * Applies business rules for the medical service catalog.
 */
class AdminMedicalServiceService {
    private final AdminMedicalServiceRepository medicalServiceRepository =
            new AdminMedicalServiceRepository();

    private void validateServiceInput(String serviceName, BigDecimal price) {
        if (serviceName == null || serviceName.trim().isEmpty() || serviceName.trim().length() < 2 || serviceName.trim().length() > 150) {
            throw new IllegalArgumentException("Tên dịch vụ phải từ 2 đến 150 ký tự.");
        }
        if (price == null || price.compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Đơn giá dịch vụ không được nhỏ hơn 0.");
        }
    }

    public List<Map<String, Object>> loadServices(String search, String serviceType, String status, int page, int pageSize) {
        return medicalServiceRepository.getMedicalServices(search, serviceType, status, page, pageSize);
    }

    public int getMedicalServicesCount(String search, String serviceType, String status) {
        return medicalServiceRepository.getMedicalServicesCount(search, serviceType, status);
    }

    public boolean createService(String serviceName, BigDecimal price, String serviceType, String status) {
        validateServiceInput(serviceName, price);
        return medicalServiceRepository.createMedicalService(serviceName, price, serviceType, status);
    }

    public boolean updateService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status) {
        validateServiceInput(serviceName, price);
        return medicalServiceRepository.updateMedicalService(serviceId, serviceName, price, serviceType, status);
    }

    public boolean updateServiceStatus(int serviceId, String status) {
        return medicalServiceRepository.updateMedicalServiceStatus(serviceId, status);
    }

    public boolean deleteService(int serviceId) {
        return medicalServiceRepository.deleteMedicalService(serviceId);
    }

    public int getTotalServices() {
        return medicalServiceRepository.getCountTotalServices();
    }
}
