package com.diabetes.monitoring.admin.management;

import com.diabetes.monitoring.admin.common.AdminRepository;
import com.diabetes.monitoring.model.User;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Facade over account and medical service persistence operations.
 */
public class AdminManagementDAO {
    private final AdminAccountDAO accountDAO = new AdminAccountDAO();
    private final AdminMedicalServiceDAO medicalServiceDAO = new AdminMedicalServiceDAO();
    public List<User> getAccounts(String search, String role, String status) { return accountDAO.getAccounts(search, role, status); }
    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) { return accountDAO.createAccount(fullName, email, passwordHash, role, status); }
    public boolean isAccountEmailExists(String email) { return accountDAO.isAccountEmailExists(email); }
    public boolean updateAccountRole(int accountId, String role) { return accountDAO.updateAccountRole(accountId, role); }
    public boolean updateAccountStatus(int accountId, String status) { return accountDAO.updateAccountStatus(accountId, status); }
    public boolean deleteAccountForAdmin(int accountId) { return accountDAO.deleteAccountForAdmin(accountId); }
    public Map<String, Object> getAccountProfileForAdminEdit(int accountId) { return accountDAO.getAccountProfileForAdminEdit(accountId); }
    public boolean updateAccountProfileByRole(int accountId, String fullName, String email, String phone, String address, String department) { return accountDAO.updateAccountProfileByRole(accountId, fullName, email, phone, address, department); }
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) { return accountDAO.getStaffAccountsQuick(status, limit); }
    public List<Map<String, Object>> getMedicalServices(String search, String serviceType, String status) { return medicalServiceDAO.getMedicalServices(search, serviceType, status); }
    public boolean createMedicalService(String serviceName, BigDecimal price, String serviceType, String status) { return medicalServiceDAO.createMedicalService(serviceName, price, serviceType, status); }
    public boolean updateMedicalService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status) { return medicalServiceDAO.updateMedicalService(serviceId, serviceName, price, serviceType, status); }
    public boolean deleteMedicalService(int serviceId) { return medicalServiceDAO.deleteMedicalService(serviceId); }
    public boolean updateMedicalServiceStatus(int serviceId, String status) { return medicalServiceDAO.updateMedicalServiceStatus(serviceId, status); }
    public int getCountTotalServices() { return medicalServiceDAO.getCountTotalServices(); }
}

/**
 * Loads and mutates account data through the shared Admin repository.
 */
class AdminAccountDAO {
    private final AdminRepository repository = new AdminRepository();
    public List<User> getAccounts(String search, String role, String status) {
        return repository.getAccounts(search, role, status);
    }
    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) {
        return repository.createAccount(fullName, email, passwordHash, role, status);
    }
    public boolean isAccountEmailExists(String email) {
        return repository.isAccountEmailExists(email);
    }
    public boolean updateAccountRole(int accountId, String role) {
        return repository.updateAccountRole(accountId, role);
    }
    public boolean updateAccountStatus(int accountId, String status) {
        return repository.updateAccountStatus(accountId, status);
    }
    public boolean deleteAccountForAdmin(int accountId) {
        return repository.deleteAccountForAdmin(accountId);
    }
    public Map<String, Object> getAccountProfileForAdminEdit(int accountId) {
        return repository.getAccountProfileForAdminEdit(accountId);
    }
    public boolean updateAccountProfileByRole(int accountId,
            String fullName,
            String email,
            String phone,
            String address,
            String department) {
        return repository.updateAccountProfileByRole(accountId, fullName, email, phone, address, department);
    }
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) {
        return repository.getStaffAccountsQuick(status, limit);
    }
}

/**
 * Loads and mutates medical service data through the shared Admin repository.
 */
class AdminMedicalServiceDAO {
    private final AdminRepository repository = new AdminRepository();
    public List<Map<String, Object>> getMedicalServices(String search, String serviceType, String status) {
        return repository.getMedicalServices(search, serviceType, status);
    }
    public boolean createMedicalService(String serviceName, BigDecimal price, String serviceType, String status) {
        return repository.createMedicalService(serviceName, price, serviceType, status);
    }
    public boolean updateMedicalService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status) {
        return repository.updateMedicalService(serviceId, serviceName, price, serviceType, status);
    }
    public boolean deleteMedicalService(int serviceId) {
        return repository.deleteMedicalService(serviceId);
    }
    public boolean updateMedicalServiceStatus(int serviceId, String status) {
        return repository.updateMedicalServiceStatus(serviceId, status);
    }
    public int getCountTotalServices() {
        return repository.getCountTotalServices();
    }
}
