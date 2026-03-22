# Testing Guide - Alchemist Laundry App

## 🧪 Complete Testing Checklist

### Prerequisites
- [ ] M-Pesa credentials configured in `mpesa_config.dart`
- [ ] Firebase project set up and connected
- [ ] Google Maps API key added
- [ ] Physical Android device or emulator ready
- [ ] Internet connection available

---

## 1️⃣ Authentication Testing

### Login Flow
```
Test Case: Login with Kenyan phone number
Steps:
1. Open app
2. Enter phone: 0712345678
3. Tap "Continue"
Expected: Welcome message, navigate to home screen
```

```
Test Case: Login with international format
Steps:
1. Open app
2. Enter phone: +254712345678
3. Tap "Continue"
Expected: Welcome message, navigate to home screen
```

```
Test Case: Empty phone number
Steps:
1. Open app
2. Leave phone field empty
3. Tap "Continue"
Expected: Error message "Please enter your phone number"
```

### Signup Flow
```
Test Case: New user signup
Steps:
1. Open app
2. Tap "Sign Up"
3. Enter name, phone, email
4. Tap "Sign Up"
Expected: Account created, navigate to home screen
```

---

## 2️⃣ Customer Features Testing

### Service Selection
```
Test Case: Browse services
Steps:
1. Login as customer
2. View home screen
3. Scroll through available services
Expected: See Wash & Fold, Dry Clean, Ironing services with prices
```

```
Test Case: Select service type
Steps:
1. On home screen
2. Tap "Wash & Fold" button
3. Tap "Dry Clean" button
4. Tap "Ironing" button
Expected: Selected service type highlighted, border changes color
```

### Cart Management
```
Test Case: Add items to cart
Steps:
1. On home screen
2. Tap "+" button on a service
3. Observe cart icon badge
Expected: Quantity increases, cart badge shows total items
```

```
Test Case: Remove items from cart
Steps:
1. Add items to cart
2. Tap "-" button
Expected: Quantity decreases, cart badge updates
```

```
Test Case: View cart
Steps:
1. Add items to cart
2. Tap cart icon in app bar
Expected: Navigate to order review screen with all items
```

### Order Creation
```
Test Case: Create order with cash payment
Steps:
1. Add items to cart
2. Tap cart icon
3. Select pickup date
4. Select delivery date
5. Tap location picker, select location
6. Add special instructions
7. Select "Cash" payment method
8. Tap "Place Order"
Expected: Order created, success message, navigate to order details
```

```
Test Case: Create order with M-Pesa payment
Steps:
1. Add items to cart
2. Tap cart icon
3. Complete order details
4. Select "M-Pesa" payment method
5. Tap "Place Order"
6. Enter M-Pesa phone number in dialog
7. Tap "Continue"
Expected: 
- STK push sent to phone
- Payment prompt appears on phone
- Enter M-Pesa PIN
- Payment processed
- Order status updated
```

```
Test Case: Empty cart submission
Steps:
1. Navigate to create order screen without items
2. Tap "Place Order"
Expected: Error message "No items in cart"
```

### Order Tracking
```
Test Case: View order history
Steps:
1. Login as customer
2. Tap orders icon in app bar
Expected: List of all user orders with status
```

```
Test Case: View order details
Steps:
1. Go to orders screen
2. Tap on an order
Expected: Full order details with items, status, location, payment info
```

---

## 3️⃣ Admin Features Testing

### Dashboard
```
Test Case: View admin dashboard
Steps:
1. Login as admin (requires admin code)
2. View dashboard
Expected: 
- Total orders metric
- Pending orders metric
- Ready orders metric
- Revenue metric
- 7-day revenue chart
```

```
Test Case: Filter orders
Steps:
1. On admin dashboard
2. Tap "Pending" filter
3. Tap "Ready" filter
4. Tap "Delivered" filter
5. Tap "All" filter
Expected: Order list updates based on selected filter
```

### Order Management
```
Test Case: Update order status
Steps:
1. On admin dashboard
2. Find a pending order
3. Tap three-dot menu
4. Select "Picked Up"
Expected: Order status updated, UI refreshes
```

```
Test Case: Navigate to customer location
Steps:
1. On admin dashboard
2. Find order with location
3. Tap map icon
Expected: Google Maps opens with customer location
```

### Service Management
```
Test Case: Add new service
Steps:
1. Login as admin
2. Tap inventory icon
3. Tap "Add Service" button
4. Enter service details
5. Tap "Save"
Expected: New service added, appears in list
```

```
Test Case: Edit service
Steps:
1. On admin services screen
2. Tap edit icon on a service
3. Modify details
4. Tap "Save"
Expected: Service updated
```

```
Test Case: Delete service
Steps:
1. On admin services screen
2. Tap delete icon on a service
3. Confirm deletion
Expected: Service removed from list
```

---

## 4️⃣ Payment Testing

### M-Pesa STK Push
```
Test Case: Successful M-Pesa payment
Steps:
1. Create order with M-Pesa payment
2. Enter phone: 0712345678
3. Wait for STK push
4. Enter M-Pesa PIN on phone
5. Confirm payment
Expected:
- Payment status: Processing → Completed
- Order status: Pending → Paid
- Receipt number saved
```

```
Test Case: M-Pesa payment timeout
Steps:
1. Create order with M-Pesa payment
2. Wait for STK push
3. Don't enter PIN (let it timeout)
Expected:
- Payment status: Processing → Failed
- Error message shown
- Order remains pending
```

```
Test Case: M-Pesa payment cancellation
Steps:
1. Create order with M-Pesa payment
2. Wait for STK push
3. Cancel on phone
Expected:
- Payment status: Processing → Cancelled
- Error message shown
```

### Cash Payment
```
Test Case: Cash payment flow
Steps:
1. Create order with Cash payment
2. Complete order
Expected:
- Order created successfully
- Payment status: Completed
- Message: "Payment will be collected on pickup"
```

---

## 5️⃣ Location Services Testing

### Location Picker
```
Test Case: Select location on map
Steps:
1. On create order screen
2. Tap location picker
3. Drag map to desired location
4. Tap "Confirm Location"
Expected: Location coordinates saved, shown on order screen
```

```
Test Case: Use current location
Steps:
1. On create order screen
2. Tap location picker
3. Tap "Use Current Location" button
Expected: Map centers on current location
```

```
Test Case: Location permission denied
Steps:
1. Deny location permission
2. Try to pick location
Expected: Fallback to manual selection, no crash
```

---

## 6️⃣ Firebase Integration Testing

### Real-time Updates
```
Test Case: Order status updates
Steps:
1. Create order as customer
2. Login as admin on another device
3. Update order status
4. Check customer device
Expected: Order status updates in real-time
```

### Offline Mode
```
Test Case: Create order offline
Steps:
1. Disable internet
2. Create order
Expected: Order saved locally, syncs when online
```

---

## 7️⃣ Edge Cases & Error Handling

### Network Errors
```
Test Case: No internet connection
Steps:
1. Disable internet
2. Try to create order
Expected: Graceful fallback to local storage
```

### Invalid Input
```
Test Case: Invalid phone number
Steps:
1. Enter phone: "123"
2. Try to login
Expected: Validation error or graceful handling
```

### Empty States
```
Test Case: No orders
Steps:
1. Login as new user
2. Go to orders screen
Expected: Empty state with message "No orders yet"
```

### Payment Failures
```
Test Case: Insufficient M-Pesa balance
Steps:
1. Create order with M-Pesa
2. Use account with insufficient balance
Expected: Payment fails, error message shown
```

---

## 8️⃣ Performance Testing

### Load Testing
```
Test Case: Multiple orders
Steps:
1. Create 50+ orders
2. Navigate to orders screen
3. Scroll through list
Expected: Smooth scrolling, no lag
```

### Animation Performance
```
Test Case: UI animations
Steps:
1. Navigate between screens
2. Add/remove cart items
3. Update order status
Expected: Smooth 60fps animations
```

---

## 9️⃣ UI/UX Testing

### Responsive Design
```
Test Case: Different screen sizes
Steps:
1. Test on small phone (5")
2. Test on large phone (6.5")
3. Test on tablet
Expected: UI adapts properly, no overflow
```

### Theme Consistency
```
Test Case: Color scheme
Steps:
1. Navigate through all screens
Expected: Consistent blue theme, proper contrast
```

---

## 🔟 Security Testing

### Authentication
```
Test Case: Unauthorized access
Steps:
1. Try to access admin screen without admin role
Expected: Access denied or redirect
```

### Data Privacy
```
Test Case: User data isolation
Steps:
1. Login as User A
2. Try to view User B's orders
Expected: Only own orders visible
```

---

## 📊 Test Results Template

| Test Case | Status | Notes | Date |
|-----------|--------|-------|------|
| Login with phone | ⬜ | | |
| Add to cart | ⬜ | | |
| Create order | ⬜ | | |
| M-Pesa payment | ⬜ | | |
| Admin dashboard | ⬜ | | |
| Update order status | ⬜ | | |
| Location picker | ⬜ | | |
| Real-time updates | ⬜ | | |

Legend: ✅ Pass | ❌ Fail | ⚠️ Warning | ⬜ Not Tested

---

## 🐛 Bug Reporting Template

```
**Bug Title:** [Short description]

**Severity:** Critical / High / Medium / Low

**Steps to Reproduce:**
1. 
2. 
3. 

**Expected Result:**

**Actual Result:**

**Screenshots:**

**Device Info:**
- Device: 
- OS Version: 
- App Version: 

**Additional Notes:**
```

---

## ✅ Sign-off Checklist

Before production deployment:
- [ ] All critical test cases passed
- [ ] M-Pesa payments working end-to-end
- [ ] Firebase real-time updates working
- [ ] No crashes or ANRs
- [ ] Performance acceptable (60fps)
- [ ] Security tests passed
- [ ] Admin features working
- [ ] Customer features working
- [ ] Error handling verified
- [ ] Offline mode tested

---

**Happy Testing! 🚀**
