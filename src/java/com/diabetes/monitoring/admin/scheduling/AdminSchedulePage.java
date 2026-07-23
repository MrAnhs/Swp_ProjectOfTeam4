package com.diabetes.monitoring.admin.scheduling;

import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Pagination metadata for admin schedule lists.
 */
public class AdminSchedulePage {
    private final List<Map<String, Object>> items;
    private final int currentPage;
    private final int pageSize;
    private final int totalRecords;
    private final int totalPages;

    public AdminSchedulePage(List<Map<String, Object>> items,
            int currentPage,
            int pageSize,
            int totalRecords) {

        this.items = items == null ? Collections.emptyList() : items;
        this.pageSize = normalizePageSize(pageSize);
        this.totalRecords = Math.max(0, totalRecords);
        this.totalPages = Math.max(1,
                (int) Math.ceil(this.totalRecords / (double) this.pageSize));
        this.currentPage = Math.min(Math.max(1, currentPage), this.totalPages);
    }

    public List<Map<String, Object>> getItems() {
        return items;
    }

    public int getCurrentPage() {
        return currentPage;
    }

    public int getPageSize() {
        return pageSize;
    }

    public int getTotalRecords() {
        return totalRecords;
    }

    public int getTotalPages() {
        return totalPages;
    }

    public int getStartRecord() {
        return totalRecords == 0 ? 0 : ((currentPage - 1) * pageSize) + 1;
    }

    public int getEndRecord() {
        return totalRecords == 0 ? 0 : Math.min(totalRecords,
                currentPage * pageSize);
    }

    private int normalizePageSize(int value) {
        return value == 20 || value == 50 ? value : 10;
    }
}