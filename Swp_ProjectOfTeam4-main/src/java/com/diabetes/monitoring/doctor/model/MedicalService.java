package com.diabetes.monitoring.doctor.model;

import java.math.BigDecimal;

public class MedicalService {

    private int serviceId;
    private String serviceName;
    private BigDecimal price;
    private String serviceType;
    private String status;

    public int getServiceId() {
        return serviceId;
    }

    public void setServiceId(int serviceId) {
        this.serviceId = serviceId;
    }

    public String getServiceName() {
        return serviceName;
    }

    public String getServiceNameDisplay() {
        if ("Xét nghiệm HbA1c".equals(serviceName)
                || "HbA1c Test".equals(serviceName)) {
            return "Xét nghiệm đường huyết";
        }
        return serviceName;
    }

    public void setServiceName(String serviceName) {
        this.serviceName = serviceName;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }

    public String getServiceType() {
        return serviceType;
    }

    public void setServiceType(String serviceType) {
        this.serviceType = serviceType;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
