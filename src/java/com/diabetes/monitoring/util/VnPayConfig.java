package com.diabetes.monitoring.util;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

public class VnPayConfig {
    public static final String vnp_TmnCode = "G97JIHSV";
    public static final String vnp_HashSecret = "2IWUPI9KL2IC62TIVBB5AJ3F03BFND3O";
    public static final String vnp_Url = "https://sandbox.vnpayment.vn/paymentv2/vpcpay.html";
    
    // HMAC-SHA512 encryption
    public static String hmacSHA512(final String key, final String data) {
        try {
            if (key == null || data == null) {
                throw new NullPointerException("Key and data cannot be null");
            }
            final Mac hmac512 = Mac.getInstance("HmacSHA512");
            byte[] hmacKeyBytes = key.getBytes(StandardCharsets.UTF_8);
            final SecretKeySpec secretKey = new SecretKeySpec(hmacKeyBytes, "HmacSHA512");
            hmac512.init(secretKey);
            byte[] dataBytes = data.getBytes(StandardCharsets.UTF_8);
            byte[] result = hmac512.doFinal(dataBytes);
            StringBuilder sb = new StringBuilder(2 * result.length);
            for (byte b : result) {
                sb.append(String.format("%02x", b & 0xff));
            }
            return sb.toString();
        } catch (Exception ex) {
            ex.printStackTrace();
            return "";
        }
    }

    // Build the query string and sign all vnp_ fields
    public static String hashAllFields(Map<String, String> fields) {
        List<String> fieldNames = new ArrayList<>();
        for (String fieldName : fields.keySet()) {
            String fieldValue = fields.get(fieldName);
            if (fieldName != null && fieldName.startsWith("vnp_") 
                    && !fieldName.equals("vnp_SecureHash") 
                    && !fieldName.equals("vnp_SecureHashType") 
                    && fieldValue != null && !fieldValue.isEmpty()) {
                fieldNames.add(fieldName);
            }
        }
        Collections.sort(fieldNames);
        StringBuilder sb = new StringBuilder();
        Iterator<String> itr = fieldNames.iterator();
        while (itr.hasNext()) {
            String fieldName = itr.next();
            String fieldValue = fields.get(fieldName);
            try {
                sb.append(fieldName).append("=").append(URLEncoder.encode(fieldValue, StandardCharsets.UTF_8.toString()));
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
            if (itr.hasNext()) {
                sb.append("&");
            }
        }
        return hmacSHA512(vnp_HashSecret, sb.toString());
    }
}
