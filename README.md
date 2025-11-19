# Restaurant_Chain
# Restaurant Chain Smart Contract

A blockchain-based restaurant ordering and payment system that enables transparent transactions between customers, restaurants, and servers.

## Overview

RestaurantChain is a decentralized smart contract that manages the complete lifecycle of restaurant orders, from menu management to payment processing and customer feedback. It provides a trustless system where payments are handled directly on-chain with full transparency.

## Key Features

### 🍽️ Digital Menu Management
- Restaurant can add and update menu items
- Each item has a name, price, and availability status
- Real-time menu availability updates

### 📱 Order Management System
- Customers place orders by selecting menu items
- Automatic total calculation based on menu prices
- Complete order tracking from placement to service

### 💳 Direct Payment Processing
- Customers pay directly to restaurant address via smart contract
- Optional tipping system for servers
- Payment verification and confirmation

### ⭐ Rating & Feedback System
- Customers can rate completed orders (0-5 stars)
- Ratings are permanently recorded on-chain
- Feedback tied to specific orders

### 👥 Role-Based Access Control
- Restaurant: Manages menu and confirms payments
- Server: Marks orders as served
- Customers: Only authorized addresses can place orders (max 10 customers)

## Smart Contract Structure

### Data Structures

**MenuItem**
```
- id: Unique menu item identifier
- name: Item name (e.g., "Margherita Pizza")
- price: Price in wei
- isAvailable: Whether item can be ordered
```

**Order**
```
- id: Unique order identifier
- customer: Address of customer who placed order
- itemIds: Array of menu items in the order
- totalAmount: Total price in wei
- isPaid: Payment status
- isServed: Service status
- timestamp: Order creation time
- rating: Customer rating (0-5 stars)
```

## Main Functions

### For Restaurant Owner

**addMenuItem(name, price)**
- Add new items to the menu
- Sets item as available by default
- Emits `MenuItemAdded` event

**updateMenuItemAvailability(itemId, isAvailable)**
- Toggle item availability (e.g., sold out items)
- Prevents customers from ordering unavailable items

**confirmPayment(orderId)**
- Manually confirm payment received (if needed)
- Marks order as paid
- Emits `OrderPaid` event

### For Customers (Authorized Only)

**placeOrder(itemIds[])**
- Create new order with selected menu items
- Validates all items are available
- Calculates total automatically
- Emits `OrderPlaced` event

**payRestaurant(orderId)**
- Pay for an order directly on-chain
- Sends payment to restaurant address
- Requires exact payment amount (order total)
- Automatically marks order as paid
- Emits `RestaurantPaymentSent` and `OrderPaid` events

**tipServer()**
- Send tip directly to server address
- Any amount accepted (must be > 0)
- Independent of order payment
- Emits `TipSent` event

**rateOrder(orderId, rating)**
- Rate a completed order (0-5 stars)
- Can only rate your own served orders
- Rating is permanent once submitted
- Emits `OrderRated` event

**getCustomerOrders()**
- View all your order IDs
- Returns array of order IDs

### For Server

**serveOrder(orderId)**
- Mark an order as served
- Requires order to be paid first
- Emits `OrderServed` event

### View Functions (Public)

**getOrderDetails(orderId)**
- Get complete order information
- Returns: customer, itemIds, totalAmount, isPaid, isServed, timestamp, rating

**getAddresses()**
- Get restaurant and server addresses
- Useful for verification

**menuItems(itemId)** (public mapping)
- View menu item details by ID

**orders(orderId)** (public mapping)
- View order details by ID

**authorizedCustomers(address)** (public mapping)
- Check if an address is authorized to order

## Events

The contract emits the following events:

- `MenuItemAdded(id, name, price)`: New menu item added
- `OrderPlaced(orderId, customer, totalAmount)`: New order created
- `OrderPaid(orderId, customer)`: Payment confirmed
- `OrderServed(orderId, customer)`: Order marked as served
- `OrderRated(orderId, customer, rating)`: Customer rating submitted
- `TipSent(customer, server, amount)`: Tip sent to server
- `RestaurantPaymentSent(customer, restaurant, amount)`: Payment sent to restaurant

## Access Control

### Three Main Roles

1. **Restaurant** (`onlyRestaurant`)
   - Add menu items
   - Update item availability
   - Confirm payments

2. **Server** (`onlyServer`)
   - Mark orders as served

3. **Authorized Customers** (`onlyAuthorizedCustomers`)
   - Place orders
   - Make payments
   - Send tips
   - Rate orders
   - View their orders

## Deployment

```solidity
constructor(
    address _restaurantAddress,
    address _serverAddress, 
    address[10] memory _customers
)
```

**Parameters:**
- `_restaurantAddress`: Ethereum address that will receive payments
- `_serverAddress`: Ethereum address that will receive tips
- `_customers`: Array of exactly 10 customer addresses authorized to order

**Example:**
```javascript
const restaurantAddr = "0x1234...";
const serverAddr = "0x5678...";
const customers = [
    "0xabc...", "0xdef...", "0x123...", "0x456...", "0x789...",
    "0xaaa...", "0xbbb...", "0xccc...", "0xddd...", "0xeee..."
];

const contract = await RestaurantChain.deploy(
    restaurantAddr, 
    serverAddr, 
    customers
);
```

## Complete Order Workflow

### Standard Flow

1. **Restaurant Setup** (One-time)
   ```solidity
   addMenuItem("Margherita Pizza", 0.01 ether);
   addMenuItem("Caesar Salad", 0.005 ether);
   addMenuItem("Tiramisu", 0.007 ether);
   ```

2. **Customer Orders**
   ```solidity
   // Customer places order for items 1 and 3
   placeOrder([1, 3]); // Returns orderId
   ```

3. **Customer Pays**
   ```solidity
   // Pay for order #1 with exact amount
   payRestaurant(1, {value: 0.017 ether});
   ```

4. **Server Serves**
   ```solidity
   // Server marks order as served
   serveOrder(1);
   ```

5. **Customer Tips & Rates**
   ```solidity
   // Optional: Send tip to server
   tipServer({value: 0.002 ether});
   
   // Rate the experience
   rateOrder(1, 5); // 5 stars
   ```

## Payment Flow

```
Customer -> Smart Contract -> Restaurant Address
                     |
                     v
              Server Address (tips)
```

- **Order payments** flow directly to restaurant address
- **Tips** flow directly to server address
- All transactions are recorded on-chain with events

## Security Features

### Access Control
- Role-based permissions prevent unauthorized actions
- Only 10 pre-authorized customer addresses can interact
- Restaurant and server addresses fixed at deployment

### Payment Safety
- Requires exact payment amount (no overpayment)
- Payment validation before marking as paid
- Direct transfers reduce custody risk

### Order Validation
- All menu items verified before order creation
- Checks item availability in real-time
- Prevents ordering non-existent items

### Rating Integrity
- Can only rate your own orders
- Order must be served before rating
- Rating range enforced (0-5 stars)

## Use Cases

1. **Quick Service Restaurants**: Fast food chains with digital ordering
2. **Food Courts**: Multiple vendors with unified payment system
3. **Coffee Shops**: Simple menu with quick transactions
4. **Catering Services**: Pre-authorized client ordering
5. **Corporate Cafeterias**: Employee meal programs with authorized users

## Limitations & Considerations

### Fixed Customer List
- Only 10 customers can be authorized at deployment
- Cannot add new customers after deployment
- Consider deploying new contract for different customer groups

### Gas Costs
- Each transaction requires gas fees
- Suitable for higher-value transactions
- Consider Layer 2 solutions for micro-transactions

### Menu Management
- No function to remove menu items
- Items can only be made unavailable
- Menu item count continuously increases

## Example Scenarios

### Scenario 1: Lunch Order
```javascript
// Restaurant adds daily special
addMenuItem("Today's Special", 0.015 ether);

// Customer orders special + salad
placeOrder([4, 2]); // orderId = 1

// Customer pays
payRestaurant(1, {value: 0.02 ether});

// Server prepares and serves
serveOrder(1);

// Happy customer tips and rates
tipServer({value: 0.003 ether});
rateOrder(1, 5);
```

### Scenario 2: Item Sold Out
```javascript
// Restaurant runs out of tiramisu
updateMenuItemAvailability(3, false);

// Customer tries to order - transaction will revert
placeOrder([3]); // ❌ Fails: "Menu item is not available"
```

## Potential Enhancements

Consider these improvements for production use:

1. **Dynamic Customer Authorization**: Allow adding/removing customers
2. **Order Cancellation**: Let customers cancel unpaid orders
3. **Partial Payments**: Support split bills or partial payments
4. **Menu Item Removal**: Function to delete outdated items
5. **Loyalty Program**: Track frequent customers and reward points
6. **Order History**: Enhanced querying by date/status
7. **Multi-Restaurant Support**: Single contract for restaurant chains
8. **Refund Mechanism**: Handle order cancellations and refunds

## Testing Checklist

- ✅ Deploy with correct addresses
- ✅ Add menu items as restaurant
- ✅ Verify unauthorized users cannot place orders
- ✅ Place order and verify total calculation
- ✅ Pay with exact amount
- ✅ Verify payment received by restaurant address
- ✅ Server marks order as served
- ✅ Customer rates order
- ✅ Send tip and verify server receives it
- ✅ Test access control on all functions

## License

MIT License - See contract header for details

## Version

Solidity ^0.8.0
