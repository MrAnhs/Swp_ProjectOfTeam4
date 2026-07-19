package com.diabetes.monitoring.admin.management;

import com.diabetes.monitoring.model.User;

import java.math.BigDecimal;
import java.util.List;
import java.util.Map;

/**
 * Provides account and medical service management use cases.
 */
public class AdminManagementService {
    private final AdminAccountService accountService = new AdminAccountService();
    private final AdminMedicalServiceService medicalServiceService = new AdminMedicalServiceService();
    public List<User> loadAccounts(String search, String role, String status) { return accountService.loadAccounts(search, role, status); }
    public boolean isAccountEmailExists(String email) { return accountService.isAccountEmailExists(email); }
    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) { return accountService.createAccount(fullName, email, passwordHash, role, status); }
    public boolean updateAccountRole(int accountId, String role) { return accountService.updateAccountRole(accountId, role); }
    public boolean updateAccountStatus(int accountId, String status) { return accountService.updateAccountStatus(accountId, status); }
    public boolean deleteAccount(int accountId) { return accountService.deleteAccount(accountId); }
    public Map<String, Object> getAccountProfile(int accountId) { return accountService.getAccountProfile(accountId); }
    public boolean updateAccountProfileByRole(int accountId, String fullName, String email, String phone, String address, String department) { return accountService.updateAccountProfileByRole(accountId, fullName, email, phone, address, department); }
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) { return accountService.getStaffAccountsQuick(status, limit); }
    public List<Map<String, Object>> loadServices(String search, String serviceType, String status) { return medicalServiceService.loadServices(search, serviceType, status); }
    public boolean createService(String serviceName, BigDecimal price, String serviceType, String status) { return medicalServiceService.createService(serviceName, price, serviceType, status); }
    public boolean updateService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status) { return medicalServiceService.updateService(serviceId, serviceName, price, serviceType, status); }
    public boolean deleteService(int serviceId) { return medicalServiceService.deleteService(serviceId); }
    public boolean updateServiceStatus(int serviceId, String status) { return medicalServiceService.updateServiceStatus(serviceId, status); }
    public int getCountTotalServices() { return medicalServiceService.getTotalServices(); }
}

/**
 * Applies business rules for account management.
 */
class AdminAccountService {
    private final AdminAccountDAO accountDAO = new AdminAccountDAO();
    public List<User> loadAccounts(String search, String role, String status) {
        return accountDAO.getAccounts(search, role, status);
    }
    public boolean isAccountEmailExists(String email) {
        return accountDAO.isAccountEmailExists(email);
    }
    public boolean createAccount(String fullName, String email, String passwordHash, String role, String status) {
        return accountDAO.createAccount(fullName, email, passwordHash, role, status);
    }
    public boolean updateAccountRole(int accountId, String role) {
        return accountDAO.updateAccountRole(accountId, role);
    }
    public boolean updateAccountStatus(int accountId, String status) {
        return accountDAO.updateAccountStatus(accountId, status);
    }
    public boolean deleteAccount(int accountId) {
        return accountDAO.deleteAccountForAdmin(accountId);
    }
    public Map<String, Object> getAccountProfile(int accountId) {
        return accountDAO.getAccountProfileForAdminEdit(accountId);
    }
    public boolean updateAccountProfileByRole(int accountId,
            String fullName,
            String email,
            String phone,
            String address,
            String department) {
        return accountDAO.updateAccountProfileByRole(accountId, fullName, email, phone, address, department);
    }
    public List<Map<String, Object>> getStaffAccountsQuick(String status, int limit) {
        return accountDAO.getStaffAccountsQuick(status, limit);
    }
}

/**
 * Applies business rules for the medical service catalog.
 */
class AdminMedicalServiceService {
    private final AdminMedicalServiceDAO medicalServiceDAO = new AdminMedicalServiceDAO();
    public List<Map<String, Object>> loadServices(String search, String serviceType, String status) {
        return medicalServiceDAO.getMedicalServices(search, serviceType, status);
    }
    public boolean createService(String serviceName, BigDecimal price, String serviceType, String status) {
        return medicalServiceDAO.createMedicalService(serviceName, price, serviceType, status);
    }
    public boolean updateService(int serviceId, String serviceName, BigDecimal price, String serviceType, String status) {
        return medicalServiceDAO.updateMedicalService(serviceId, serviceName, price, serviceType, status);
    }
    public boolean updateServiceStatus(int serviceId, String status) {
        return medicalServiceDAO.updateMedicalServiceStatus(serviceId, status);
    }
    public boolean deleteService(int serviceId) {
        return medicalServiceDAO.deleteMedicalService(serviceId);
    }
    public int getTotalServices() {
        return medicalServiceDAO.getCountTotalServices();
    }
}
