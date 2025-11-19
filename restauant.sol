// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RestaurantChain {
    address public restaurantAddress;  // Adresse du restaurant
    address public serverAddress;      // Adresse du serveur
    uint public menuItemCount;         // Nombre d'articles au menu
    uint public orderCount;            // Compteur de commandes

    // Structure pour les articles du menu
    struct MenuItem {
        uint id;
        string name;
        uint price;
        bool isAvailable;
    }

    // Structure pour les commandes
    struct Order {
        uint id;
        address customer;
        uint[] itemIds;
        uint totalAmount;
        bool isPaid;
        bool isServed;
        uint timestamp;
        uint8 rating;       // Note de 0-5 étoiles
    }

    // Mapping pour les articles du menu par ID
    mapping(uint => MenuItem) public menuItems;
    
    // Mapping pour les commandes par ID
    mapping(uint => Order) public orders;
    
    // Liste des adresses clients autorisées
    mapping(address => bool) public authorizedCustomers;
    
    // Évènements
    event MenuItemAdded(uint id, string name, uint price);
    event OrderPlaced(uint orderId, address customer, uint totalAmount);
    event OrderPaid(uint orderId, address customer);
    event OrderServed(uint orderId, address customer);
    event OrderRated(uint orderId, address customer, uint8 rating);
    event TipSent(address customer, address server, uint amount);
    event RestaurantPaymentSent(address customer, address restaurant, uint amount);

    // Modifier pour restreindre les fonctions au restaurant uniquement
    modifier onlyRestaurant() {
        require(msg.sender == restaurantAddress, "Only restaurant can call this function");
        _;
    }

    // Modifier pour restreindre les fonctions au serveur uniquement
    modifier onlyServer() {
        require(msg.sender == serverAddress, "Only server can call this function");
        _;
    }

    // Modifier pour restreindre les fonctions aux clients autorisés
    modifier onlyAuthorizedCustomers() {
        require(authorizedCustomers[msg.sender], "Only authorized customers can call this function");
        _;
    }

    constructor(address _restaurantAddress, address _serverAddress, address[10] memory _customers) {
        restaurantAddress = _restaurantAddress;
        serverAddress = _serverAddress;
        
        // Autoriser les 10 adresses clients
        for (uint i = 0; i < _customers.length; i++) {
            authorizedCustomers[_customers[i]] = true;
        }
        
        menuItemCount = 0;
        orderCount = 0;
    }

    // Fonction pour que le restaurant ajoute des articles au menu
    function addMenuItem(string memory _name, uint _price) external onlyRestaurant {
        menuItemCount++;
        menuItems[menuItemCount] = MenuItem({
            id: menuItemCount, 
            name: _name, 
            price: _price, 
            isAvailable: true
        });
        
        emit MenuItemAdded(menuItemCount, _name, _price);
    }

    // Fonction pour que le restaurant mette à jour la disponibilité d'un article
    function updateMenuItemAvailability(uint _itemId, bool _isAvailable) external onlyRestaurant {
        require(_itemId > 0 && _itemId <= menuItemCount, "Invalid menu item ID");
        menuItems[_itemId].isAvailable = _isAvailable;
    }

    // Fonction pour que les clients passent une commande
    function placeOrder(uint[] memory _itemIds) external onlyAuthorizedCustomers {
        require(_itemIds.length > 0, "Order must contain at least one item");
        
        uint totalAmount = 0;
        
        // Vérifier que tous les articles sont disponibles et calculer le montant total
        for (uint i = 0; i < _itemIds.length; i++) {
            uint itemId = _itemIds[i];
            require(itemId > 0 && itemId <= menuItemCount, "Invalid menu item ID");
            require(menuItems[itemId].isAvailable, "Menu item is not available");
            
            totalAmount += menuItems[itemId].price;
        }
        
        // Créer la commande
        orderCount++;
        orders[orderCount] = Order({
            id: orderCount,
            customer: msg.sender,
            itemIds: _itemIds,
            totalAmount: totalAmount,
            isPaid: false,
            isServed: false,
            timestamp: block.timestamp,
            rating: 0
        });
        
        emit OrderPlaced(orderCount, msg.sender, totalAmount);
    }

    // Fonction pour que le restaurant marque une commande comme payée après avoir reçu le paiement direct
    function confirmPayment(uint _orderId) external onlyRestaurant {
        Order storage order = orders[_orderId];
        require(order.id > 0, "Order does not exist");
        require(!order.isPaid, "Order already paid");
        
        order.isPaid = true;
        
        emit OrderPaid(_orderId, order.customer);
    }

    // Fonction pour que les clients paient directement au restaurant (cette fonction est juste pour l'événement et la référence)
    function payRestaurant(uint _orderId) external payable onlyAuthorizedCustomers {
        Order storage order = orders[_orderId];
        require(order.id > 0, "Order does not exist");
        require(order.customer == msg.sender, "Not your order");
        require(!order.isPaid, "Order already paid");
        require(msg.value == order.totalAmount, "Incorrect payment amount");

        // Le paiement est envoyé directement à l'adresse du restaurant
        payable(restaurantAddress).transfer(msg.value);
        
        // Marquer automatiquement comme payé
        order.isPaid = true;
        
        emit RestaurantPaymentSent(msg.sender, restaurantAddress, msg.value);
        emit OrderPaid(_orderId, msg.sender);
    }

    // Fonction pour envoyer un pourboire directement au serveur
    function tipServer() external payable onlyAuthorizedCustomers {
        require(msg.value > 0, "Tip amount must be greater than 0");
        
        // Le pourboire est envoyé directement à l'adresse du serveur
        payable(serverAddress).transfer(msg.value);
        
        emit TipSent(msg.sender, serverAddress, msg.value);
    }

    // Fonction pour que le serveur marque une commande comme servie
    function serveOrder(uint _orderId) external onlyServer {
        Order storage order = orders[_orderId];
        require(order.id > 0, "Order does not exist");
        require(order.isPaid, "Order not paid yet");
        require(!order.isServed, "Order already served");
        
        order.isServed = true;
        
        emit OrderServed(_orderId, order.customer);
    }

    // Fonction pour que les clients notent leur commande
    function rateOrder(uint _orderId, uint8 _rating) external onlyAuthorizedCustomers {
        Order storage order = orders[_orderId];
        require(order.id > 0, "Order does not exist");
        require(order.customer == msg.sender, "Not your order");
        require(order.isServed, "Order not served yet");
        require(_rating >= 0 && _rating <= 5, "Rating must be between 0 and 5");
        
        order.rating = _rating;
        
        emit OrderRated(_orderId, msg.sender, _rating);
    }

    // Fonction pour vérifier les commandes d'un client
    function getCustomerOrders() external view onlyAuthorizedCustomers returns (uint[] memory) {
        // Compter d'abord le nombre de commandes du client
        uint count = 0;
        for (uint i = 1; i <= orderCount; i++) {
            if (orders[i].customer == msg.sender) {
                count++;
            }
        }
        
        // Créer et remplir le tableau des IDs de commandes
        uint[] memory customerOrderIds = new uint[](count);
        uint index = 0;
        for (uint i = 1; i <= orderCount; i++) {
            if (orders[i].customer == msg.sender) {
                customerOrderIds[index] = orders[i].id;
                index++;
            }
        }
        
        return customerOrderIds;
    }

    // Fonction pour obtenir les détails d'une commande spécifique
    function getOrderDetails(uint _orderId) external view returns (
        address customer,
        uint[] memory itemIds,
        uint totalAmount,
        bool isPaid,
        bool isServed,
        uint timestamp,
        uint8 rating
    ) {
        Order storage order = orders[_orderId];
        require(order.id > 0, "Order does not exist");
        
        return (
            order.customer,
            order.itemIds,
            order.totalAmount,
            order.isPaid,
            order.isServed,
            order.timestamp,
            order.rating
        );
    }

    // Fonction pour obtenir les adresses du restaurant et du serveur
    function getAddresses() external view returns (address restaurant, address server) {
        return (restaurantAddress, serverAddress);
    }
}