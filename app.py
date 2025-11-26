import streamlit as st
import pandas as pd
from database import DatabaseManager
from datetime import datetime

# Page configuration
st.set_page_config(
    page_title="Campus Marketplace",
    page_icon="🎓",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Initialize database manager
@st.cache_resource
def get_db_manager():
    return DatabaseManager()

db = get_db_manager()

# Initialize session state
if 'logged_in_user' not in st.session_state:
    st.session_state.logged_in_user = None
if 'cart' not in st.session_state:
    st.session_state.cart = []
if 'current_page' not in st.session_state:
    st.session_state.current_page = 'marketplace'
if 'selected_product' not in st.session_state:
    st.session_state.selected_product = None

# Custom CSS
st.markdown("""
    <style>
    .product-card {
        border: 1px solid #ddd;
        border-radius: 10px;
        padding: 15px;
        margin: 10px 0;
        background-color: white;
        box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    .product-title {
        font-size: 1.2rem;
        font-weight: bold;
        color: #1f77b4;
        margin-bottom: 5px;
    }
    .product-price {
        font-size: 1.5rem;
        color: #B12704;
        font-weight: bold;
    }
    .seller-info {
        color: #555;
        font-size: 0.9rem;
    }
    .buy-button {
        background-color: #ff9900;
        color: white;
        padding: 10px 20px;
        border-radius: 5px;
        border: none;
        font-weight: bold;
    }
    .main-header {
        font-size: 2rem;
        font-weight: bold;
        color: #232f3e;
        padding: 20px 0;
    }
    </style>
""", unsafe_allow_html=True)

# ==================== USER LOGIN ====================
def login_section():
    st.markdown('<p class="main-header">🎓 Welcome to Campus Marketplace</p>', unsafe_allow_html=True)
    st.markdown("### Please select your account to continue")
    
    try:
        users = db.get_all_users()
        if not users.empty:
            user_options = ["-- Select User --"] + [f"{row['User_Name']} ({row['Email_ID']})" 
                                                     for _, row in users.iterrows()]
            
            selected = st.selectbox("Login as:", user_options, key="login_select")
            
            if selected != "-- Select User --":
                user_email = selected.split('(')[1].split(')')[0]
                user_data = users[users['Email_ID'] == user_email].iloc[0]
                
                col1, col2, col3 = st.columns([1, 2, 1])
                with col2:
                    if st.button("🔐 Login", type="primary", use_container_width=True):
                        st.session_state.logged_in_user = {
                            'id': int(user_data['UserID']),
                            'name': str(user_data['User_Name']),
                            'email': str(user_data['Email_ID']),
                            'rating': float(user_data['Agg_Seller_Rating']),
                            'verification': str(user_data['Verification_Status'])
                        }
                        st.session_state.current_page = 'marketplace'
                        st.rerun()
        else:
            st.error("No users found in database. Please run the DML script first.")
    except Exception as e:
        st.error(f"Database connection error: {e}")
        st.info("Make sure SQL Server is running and database is set up.")

# ==================== MARKETPLACE HOME ====================
def marketplace_page():
    st.markdown(f"### 🏠 Campus Marketplace")
    
    # Search and filters
    col1, col2, col3 = st.columns([3, 1, 1])
    with col1:
        search_query = st.text_input("🔍 Search products", placeholder="Search by name or description...")
    with col2:
        categories = db.get_categories()
        category_filter = st.selectbox("Category", ["All"] + categories['Category_Name'].tolist())
    with col3:
        price_sort = st.selectbox("Sort by", ["Newest", "Price: Low to High", "Price: High to Low"])
    
    st.markdown("---")
    
    # Get products
    try:
        products = db.get_all_products()
        
        # Filter active products only
        products = products[products['Product_Status'] == 'Active']
        
        # Apply filters
        if search_query:
            products = products[
                products['Product_Name'].str.contains(search_query, case=False, na=False) |
                products['Description'].str.contains(search_query, case=False, na=False)
            ]
        
        if category_filter != "All":
            products = products[products['Category_Name'] == category_filter]
        
        # Apply sorting
        if price_sort == "Price: Low to High":
            products = products.sort_values('Unit_price', ascending=True)
        elif price_sort == "Price: High to Low":
            products = products.sort_values('Unit_price', ascending=False)
        else:
            products = products.sort_values('Product_ID', ascending=False)
        
        if products.empty:
            st.info("No products found matching your criteria.")
        else:
            # Display products in grid (3 columns)
            cols_per_row = 3
            rows = len(products) // cols_per_row + (1 if len(products) % cols_per_row > 0 else 0)
            
            for row_idx in range(rows):
                cols = st.columns(cols_per_row)
                for col_idx in range(cols_per_row):
                    product_idx = row_idx * cols_per_row + col_idx
                    if product_idx < len(products):
                        product = products.iloc[product_idx]
                        
                        with cols[col_idx]:
                            with st.container():
                                st.markdown(f"""
                                    <div class="product-card">
                                        <div class="product-title">{product['Product_Name']}</div>
                                        <div class="product-price">${product['Unit_price']:.2f}</div>
                                        <div class="seller-info">
                                            Seller: {product['Seller']}<br>
                                            Category: {product['Category_Name']}<br>
                                            Quantity: {product['Quantity']}
                                        </div>
                                    </div>
                                """, unsafe_allow_html=True)
                                
                                if st.button(f"View Details", key=f"view_{product['Product_ID']}", use_container_width=True):
                                    st.session_state.selected_product = int(product['Product_ID'])
                                    st.session_state.current_page = 'product_details'
                                    st.rerun()
    
    except Exception as e:
        st.error(f"Error loading products: {e}")

# ==================== PRODUCT DETAILS ====================
def product_details_page():
    product_id = st.session_state.selected_product
    
    try:
        products = db.get_all_products()
        product = products[products['Product_ID'] == product_id].iloc[0]
        
        # Get seller details
        users = db.get_all_users()
        seller = users[users['User_Name'] == product['Seller']].iloc[0]
        
        # Back button
        if st.button("← Back to Marketplace"):
            st.session_state.current_page = 'marketplace'
            st.rerun()
        
        st.markdown("---")
        
        # Product details
        col1, col2 = st.columns([1, 1])
        
        with col1:
            st.markdown(f"## {product['Product_Name']}")
            st.markdown(f"### ${product['Unit_price']:.2f}")
            st.markdown(f"**Category:** {product['Category_Name']}")
            st.markdown(f"**Available Quantity:** {product['Quantity']}")
            st.markdown(f"**Status:** {product['Product_Status']}")
            
            st.markdown("---")
            st.markdown("### Description")
            st.write(product['Description'])
        
        with col2:
            st.markdown("### Seller Information")
            st.info(f"""
                **Name:** {seller['User_Name']}  
                **Rating:** {'⭐' * int(seller['Agg_Seller_Rating'])} ({seller['Agg_Seller_Rating']:.2f})  
                **Verification:** {seller['Verification_Status']}  
                **Email:** {seller['Email_ID']}  
                **Phone:** {seller['Phone_number']}
            """)
            
            st.markdown("---")
            
            # Buy section
            if st.session_state.logged_in_user['id'] == int(seller['UserID']):
                st.warning("⚠️ This is your own listing")
            else:
                quantity = st.number_input("Quantity", min_value=1, max_value=int(product['Quantity']), value=1)
                total_price = quantity * float(product['Unit_price'])
                
                st.markdown(f"**Total Price:** ${total_price:.2f}")
                
                if st.button("🛒 Buy Now", type="primary", use_container_width=True):
                    st.session_state.cart = {
                        'product_id': int(product['Product_ID']),
                        'product_name': str(product['Product_Name']),
                        'seller_id': int(seller['UserID']),
                        'seller_name': str(seller['User_Name']),
                        'quantity': int(quantity),
                        'unit_price': float(product['Unit_price']),
                        'total_price': float(total_price)
                    }
                    st.session_state.current_page = 'checkout'
                    st.rerun()
    
    except Exception as e:
        st.error(f"Error loading product details: {e}")

# ==================== CHECKOUT ====================
def checkout_page():
    st.markdown("## 🛒 Order Summary")
    
    if not st.session_state.cart:
        st.warning("Your cart is empty!")
        if st.button("← Back to Marketplace"):
            st.session_state.current_page = 'marketplace'
            st.rerun()
        return
    
    cart = st.session_state.cart
    
    # Order summary
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.markdown("### Order Details")
        st.markdown(f"""
        **Product:** {cart['product_name']}  
        **Seller:** {cart['seller_name']}  
        **Quantity:** {cart['quantity']}  
        **Price per unit:** ${cart['unit_price']:.2f}  
        """)
        
        st.markdown("---")
        
        # Pickup point selection
        st.markdown("### Select Pickup Point")
        pickup_query = """
        SELECT PickupPointID, Location_Name, Street 
        FROM Pickup_Point 
        WHERE CampusID = 1
        ORDER BY Location_Name
        """
        pickup_points = db.fetch_data(pickup_query)
        
        pickup_options = {f"{row['Location_Name']} - {row['Street']}": int(row['PickupPointID']) 
                         for _, row in pickup_points.iterrows()}
        
        selected_pickup = st.selectbox("Pickup Location", options=list(pickup_options.keys()))
        pickup_point_id = pickup_options[selected_pickup]
    
    with col2:
        st.markdown("### Payment Summary")
        st.markdown(f"""
        **Subtotal:** ${cart['total_price']:.2f}  
        **Tax:** $0.00  
        **Total:** ${cart['total_price']:.2f}
        """)
        
        st.markdown("---")
        st.info("💰 Amount will be held in escrow until delivery is confirmed")
        
        if st.button("✅ Confirm Order", type="primary", use_container_width=True):
            try:
                # Check if product still has enough quantity
                product_check_query = f"""
                SELECT Quantity, Product_Status 
                FROM Product 
                WHERE Product_ID = {cart['product_id']}
                """
                product_data = db.fetch_data(product_check_query)
                
                if product_data.empty:
                    st.error("❌ Product not found.")
                    return
                
                current_quantity = int(product_data.iloc[0]['Quantity'])
                product_status = product_data.iloc[0]['Product_Status']
                
                if product_status != 'Active':
                    st.error("❌ This product is no longer available.")
                    return
                
                if current_quantity < cart['quantity']:
                    st.error(f"❌ Insufficient quantity. Only {current_quantity} items available.")
                    return
                
                # Create order
                success = db.add_order(
                    cart['product_id'],
                    cart['seller_id'],
                    st.session_state.logged_in_user['id'],
                    cart['quantity'],
                    'Confirmed'
                )
                
                if success:
                    # Get the order ID
                    orders = db.get_all_orders()
                    order_id = int(orders.iloc[0]['OrderID'])  # Latest order
                    
                    # Update product quantity
                    new_quantity = current_quantity - cart['quantity']
                    new_status = 'Sold' if new_quantity == 0 else 'Active'
                    
                    update_quantity_query = f"""
                    UPDATE Product 
                    SET Quantity = {new_quantity}, 
                        Product_Status = '{new_status}'
                    WHERE Product_ID = {cart['product_id']}
                    """
                    db.execute_query(update_quantity_query)
                    
                    # Create escrow
                    escrow_success = db.add_escrow(order_id, cart['total_price'], 'Held')
                    
                    # Create order collection
                    collection_query = f"""
                    INSERT INTO Order_Collection (Order_ID, Pickup_Point_ID)
                    VALUES ({order_id}, {pickup_point_id})
                    """
                    db.execute_query(collection_query)
                    
                    st.success("✅ Order placed successfully!")
                    st.balloons()
                    
                    if new_quantity == 0:
                        st.info(f"📦 Order ID: #{order_id} | Product is now SOLD OUT")
                    else:
                        st.info(f"📦 Order ID: #{order_id} | {new_quantity} items remaining")
                    
                    st.info(f"💰 Escrow Status: Held | Amount: ${cart['total_price']:.2f}")
                    
                    # Clear cart
                    st.session_state.cart = []
                    
                    # Show button to view orders
                    st.markdown("---")
                    if st.button("View My Orders", type="primary"):
                        st.session_state.current_page = 'my_purchases'
                        st.rerun()
                else:
                    st.error("❌ Failed to create order. Please try again.")
            
            except Exception as e:
                st.error(f"❌ Error processing order: {e}")
                import traceback
                st.code(traceback.format_exc())
    
    st.markdown("---")
    if st.button("← Cancel and go back"):
        st.session_state.cart = []
        st.session_state.current_page = 'product_details'
        st.rerun()
# ==================== SELL ITEM ====================
def sell_item_page():
    st.markdown("## ➕ List a New Product")
    
    if st.session_state.logged_in_user['verification'] != 'Verified':
        st.error("⚠️ Only verified users can sell items. Please contact admin to verify your account.")
        return
    
    # Track if product was successfully added
    product_added = False
    
    with st.form("sell_product_form"):
        col1, col2 = st.columns(2)
        
        with col1:
            product_name = st.text_input("Product Name *")
            
            categories = db.get_categories()
            category = st.selectbox("Category *", categories['Category_Name'].tolist())
            
            standard_price = st.number_input("Standard Price ($) *", min_value=0.01, value=100.0, step=0.01, 
                                            help="Original retail price of the item")
            quantity = st.number_input("Quantity *", min_value=1, value=1, step=1,
                                      help="Number of items available")
        
        with col2:
            # Calculate unit price automatically
            unit_price = standard_price / quantity if quantity > 0 else standard_price
            
            st.markdown("### Pricing Breakdown")
            st.info(f"""
            **Standard Price:** ${standard_price:.2f}  
            **Quantity:** {quantity}  
            **Unit Price:** ${unit_price:.2f}  
            *(Price per item)*
            """)
        
        description = st.text_area("Description *", height=150, 
                                   placeholder="Describe your item, its condition, and any important details...")
        
        st.markdown("**Note:** All fields marked with * are required")
        st.markdown("**Unit Price** is automatically calculated as: Standard Price ÷ Quantity")
        
        submitted = st.form_submit_button("📦 List Product", type="primary", use_container_width=True)
        
        if submitted:
            if product_name and description:
                category_id = int(categories[categories['Category_Name'] == category]['Category_ID'].iloc[0])
                
                # Recalculate unit price to ensure accuracy
                unit_price = standard_price / quantity
                
                success = db.add_product(
                    category_id,
                    st.session_state.logged_in_user['id'],
                    product_name,
                    description,
                    standard_price,
                    unit_price,
                    quantity,
                    'Active'
                )
                
                if success:
                    st.success(f"✅ Product listed successfully! Unit price: ${unit_price:.2f}")
                    st.balloons()
                    product_added = True
                else:
                    st.error("❌ Failed to list product. Please try again.")
            else:
                st.warning("⚠️ Please fill in all required fields.")
    
    # Button outside form - only show after successful submission
    if product_added:
        if st.button("View My Listings"):
            st.session_state.current_page = 'my_listings'
            st.rerun()
# ==================== MY PURCHASES ====================
def my_purchases_page():
    st.markdown("## 🛒 My Purchases")
    
    user_id = st.session_state.logged_in_user['id']
    
    try:
        query = f"""
        SELECT o.OrderID, o.Product_ID, o.Seller_ID, p.Product_Name, seller.User_Name as Seller,
               o.Quantity, o.Status, o.Order_Date,
               e.EscrowID, e.Amount, e.Status as Escrow_Status,
               oc.Scheduled_Date, pp.Location_Name as Pickup_Location
        FROM [Order] o
        JOIN Product p ON o.Product_ID = p.Product_ID
        JOIN [User] seller ON o.Seller_ID = seller.UserID
        LEFT JOIN Escrow e ON o.OrderID = e.OrderID
        LEFT JOIN Order_Collection oc ON o.OrderID = oc.Order_ID
        LEFT JOIN Pickup_Point pp ON oc.Pickup_Point_ID = pp.PickupPointID
        WHERE o.Buyer_ID = {user_id}
        ORDER BY o.OrderID DESC
        """
        
        orders = db.fetch_data(query)
        
        if orders.empty:
            st.info("You haven't made any purchases yet.")
            if st.button("🏠 Browse Marketplace"):
                st.session_state.current_page = 'marketplace'
                st.rerun()
        else:
            # Status filter
            status_filter = st.multiselect("Filter by Status", 
                                          options=orders['Status'].unique(),
                                          default=orders['Status'].unique())
            
            filtered_orders = orders[orders['Status'].isin(status_filter)]
            
            for _, order in filtered_orders.iterrows():
                with st.expander(f"Order #{int(order['OrderID'])} - {order['Product_Name']} (${float(order['Amount']):.2f})"):
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.markdown(f"""
                        **Product:** {order['Product_Name']}  
                        **Seller:** {order['Seller']}  
                        **Quantity:** {int(order['Quantity'])}  
                        **Order Date:** {order['Order_Date']}  
                        **Status:** {order['Status']}
                        """)
                    
                    with col2:
                        st.markdown(f"""
                        **Amount:** ${float(order['Amount']):.2f}  
                        **Escrow Status:** {order['Escrow_Status']}  
                        **Pickup:** {order['Pickup_Location'] if pd.notna(order['Pickup_Location']) else 'Not scheduled'}  
                        """)
                    
                    # Actions
                    st.markdown("---")
                    action_col1, action_col2, action_col3 = st.columns(3)
                    
                    with action_col1:
                        if order['Status'] == 'Confirmed':
                            if st.button(f"✅ Mark as Delivered", key=f"deliver_{int(order['OrderID'])}"):
                                db.update_order_status(int(order['OrderID']), 'Delivered')
                                st.success("Order marked as delivered!")
                                st.rerun()
                    
                    with action_col2:
                        if order['Status'] == 'Delivered' and order['Escrow_Status'] == 'Held':
                            if st.button(f"💰 Release Payment", key=f"release_{int(order['OrderID'])}"):
                                db.update_escrow_status(int(order['EscrowID']), 'Released')
                                st.success("Payment released to seller!")
                                st.rerun()
                    
                    with action_col3:
                        if order['Escrow_Status'] == 'Held':
                            if st.button(f"⚖️ File Dispute", key=f"dispute_{int(order['OrderID'])}"):
                                st.session_state.dispute_order = int(order['OrderID'])
                                st.session_state.current_page = 'file_dispute'
                                st.rerun()
                    
                    # Rating option
                    if order['Status'] == 'Delivered' and order['Escrow_Status'] == 'Released':
                        # Check if already rated
                        rating_check = db.fetch_data(f"SELECT * FROM Rating WHERE Order_ID = {int(order['OrderID'])}")
                        if rating_check.empty:
                            st.markdown("**Rate this transaction:**")
                            rating = st.slider("Rating", 1.0, 5.0, 5.0, 0.5, key=f"rating_{int(order['OrderID'])}")
                            if st.button(f"⭐ Submit Rating", key=f"rate_{int(order['OrderID'])}"):
                                db.add_rating(int(order['OrderID']), int(user_id), int(order['Seller_ID']), float(rating))
                                st.success("Rating submitted!")
                                st.rerun()
                        else:
                            st.success("✅ You've already rated this transaction")
    
    except Exception as e:
        st.error(f"Error loading purchases: {e}")
        import traceback
        st.code(traceback.format_exc())

# ==================== MY LISTINGS ====================
def my_listings_page():
    st.markdown("## 📊 My Listings")
    
    user_id = st.session_state.logged_in_user['id']
    
    try:
        query = f"""
        SELECT p.Product_ID, p.Product_Name, p.Description, p.Unit_price, 
               p.Quantity, p.Product_Status, c.Category_Name, p.Created_date
        FROM Product p
        JOIN Category c ON p.Category_ID = c.Category_ID
        WHERE p.Seller_ID = {user_id}
        ORDER BY p.Product_ID DESC
        """
        
        my_products = db.fetch_data(query)
        
        if my_products.empty:
            st.info("You haven't listed any products yet.")
            if st.button("➕ List a Product"):
                st.session_state.current_page = 'sell_item'
                st.rerun()
        else:
            # Summary stats
            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Total Listings", len(my_products))
            with col2:
                active_count = len(my_products[my_products['Product_Status'] == 'Active'])
                st.metric("Active", active_count)
            with col3:
                sold_count = len(my_products[my_products['Product_Status'] == 'Sold'])
                st.metric("Sold", sold_count)
            with col4:
                inactive_count = len(my_products[my_products['Product_Status'] == 'Inactive'])
                st.metric("Inactive", inactive_count)
            
            st.markdown("---")
            
            # Status tabs
            tab1, tab2, tab3, tab4 = st.tabs(["All", "Active", "Sold", "Inactive"])
            
            with tab1:
                if not my_products.empty:
                    for _, product in my_products.iterrows():
                        with st.expander(f"{product['Product_Name']} - ${float(product['Unit_price']):.2f} ({product['Product_Status']})"):
                            col1, col2 = st.columns([2, 1])
                            with col1:
                                st.markdown(f"**Category:** {product['Category_Name']}")
                                st.markdown(f"**Description:** {product['Description']}")
                                st.markdown(f"**Listed on:** {product['Created_date']}")
                            with col2:
                                st.markdown(f"**Price:** ${float(product['Unit_price']):.2f}")
                                st.markdown(f"**Quantity:** {int(product['Quantity'])}")
                                st.markdown(f"**Status:** {product['Product_Status']}")
            
            with tab2:
                active = my_products[my_products['Product_Status'] == 'Active']
                if not active.empty:
                    for _, product in active.iterrows():
                        with st.expander(f"{product['Product_Name']} - ${float(product['Unit_price']):.2f}"):
                            st.markdown(f"**Category:** {product['Category_Name']}")
                            st.markdown(f"**Quantity Available:** {int(product['Quantity'])}")
                            st.markdown(f"**Description:** {product['Description']}")
                else:
                    st.info("No active listings")
            
            with tab3:
                sold = my_products[my_products['Product_Status'] == 'Sold']
                if not sold.empty:
                    for _, product in sold.iterrows():
                        with st.expander(f"{product['Product_Name']} - ${float(product['Unit_price']):.2f}"):
                            st.markdown(f"**Category:** {product['Category_Name']}")
                            st.markdown(f"**Description:** {product['Description']}")
                            st.markdown(f"**Sold on:** {product['Created_date']}")
                else:
                    st.info("No sold items")
            
            with tab4:
                inactive = my_products[my_products['Product_Status'] == 'Inactive']
                if not inactive.empty:
                    for _, product in inactive.iterrows():
                        with st.expander(f"{product['Product_Name']} - ${float(product['Unit_price']):.2f}"):
                            st.markdown(f"**Category:** {product['Category_Name']}")
                            st.markdown(f"**Description:** {product['Description']}")
                            st.markdown(f"**Quantity:** {int(product['Quantity'])}")
                else:
                    st.info("No inactive listings")
    
    except Exception as e:
        st.error(f"Error loading listings: {e}")
        import traceback
        st.code(traceback.format_exc())

# ==================== MY ESCROWS ====================
def my_escrows_page():
    st.markdown("## 💰 My Escrow Accounts")
    
    user_id = st.session_state.logged_in_user['id']
    
    try:
        # As buyer
        query_buyer = f"""
        SELECT e.EscrowID, e.OrderID, e.Amount, e.Status, e.Created_Date, e.Release_Date,
               p.Product_Name, 'Buyer' as Role
        FROM Escrow e
        JOIN [Order] o ON e.OrderID = o.OrderID
        JOIN Product p ON o.Product_ID = p.Product_ID
        WHERE o.Buyer_ID = {user_id}
        """
        
        # As seller
        query_seller = f"""
        SELECT e.EscrowID, e.OrderID, e.Amount, e.Status, e.Created_Date, e.Release_Date,
               p.Product_Name, 'Seller' as Role
        FROM Escrow e
        JOIN [Order] o ON e.OrderID = o.OrderID
        JOIN Product p ON o.Product_ID = p.Product_ID
        WHERE o.Seller_ID = {user_id}
        """
        
        escrows_buyer = db.fetch_data(query_buyer)
        escrows_seller = db.fetch_data(query_seller)
        
        escrows = pd.concat([escrows_buyer, escrows_seller], ignore_index=True)
        
        if escrows.empty:
            st.info("No escrow accounts found.")
        else:
            # Summary metrics
            col1, col2, col3 = st.columns(3)
            with col1:
                held = escrows[escrows['Status'] == 'Held']['Amount'].sum()
                st.metric("💰 Held", f"${float(held):.2f}")
            with col2:
                released = escrows[escrows['Status'] == 'Released']['Amount'].sum()
                st.metric("✅ Released", f"${float(released):.2f}")
            with col3:
                refunded = escrows[escrows['Status'] == 'Refunded']['Amount'].sum()
                st.metric("🔄 Refunded", f"${float(refunded):.2f}")
            
            st.markdown("---")
            
            # Display escrow table
            display_df = escrows.copy()
            display_df['Amount'] = display_df['Amount'].apply(lambda x: f"${float(x):.2f}")
            st.dataframe(display_df, use_container_width=True)
    
    except Exception as e:
        st.error(f"Error loading escrows: {e}")

# ==================== FILE DISPUTE ====================
def file_dispute_page():
    st.markdown("## ⚖️ File a Dispute")
    
    if 'dispute_order' in st.session_state:
        order_id = st.session_state.dispute_order
        
        # Get order details
        query = f"""
        SELECT o.*, p.Product_Name, e.EscrowID, e.Amount
        FROM [Order] o
        JOIN Product p ON o.Product_ID = p.Product_ID
        JOIN Escrow e ON o.OrderID = e.OrderID
        WHERE o.OrderID = {order_id}
        """
        order_data = db.fetch_data(query)
        
        if not order_data.empty:
            order = order_data.iloc[0]
            
            st.info(f"""
            **Order:** #{int(order['OrderID'])} - {order['Product_Name']}  
            **Amount:** ${float(order['Amount']):.2f}  
            **Escrow ID:** {int(order['EscrowID'])}
            """)
            
            with st.form("dispute_form"):
                description = st.text_area("Describe the issue *", height=200,
                                          placeholder="Explain what went wrong with this transaction...")
                
                submitted = st.form_submit_button("Submit Dispute")
                
                if submitted:
                    if description:
                        success = db.add_dispute(
                            int(order['EscrowID']),
                            st.session_state.logged_in_user['id'],
                            description,
                            'Open'
                        )
                        
                        if success:
                            st.success("✅ Dispute filed successfully! An admin will review it.")
                            del st.session_state.dispute_order
                            if st.button("View My Disputes"):
                                st.session_state.current_page = 'my_disputes'
                                st.rerun()
                        else:
                            st.error("❌ Failed to file dispute.")
                    else:
                        st.warning("⚠️ Please describe the issue.")
        else:
            st.error("Order not found.")
    else:
        st.warning("No order selected for dispute.")
        if st.button("← Back to My Purchases"):
            st.session_state.current_page = 'my_purchases'
            st.rerun()

# ==================== MY DISPUTES ====================
def my_disputes_page():
    st.markdown("## ⚖️ My Disputes")
    
    user_id = st.session_state.logged_in_user['id']
    
    try:
        query = f"""
        SELECT d.Dispute_ID, d.EscrowID, d.Description, d.Status, 
               d.Open_Date, d.Resolved_Date, d.Resolution_Details,
               e.OrderID, e.Amount
        FROM Dispute d
        JOIN Escrow e ON d.EscrowID = e.EscrowID
        WHERE d.FiledByUserID = {user_id}
        ORDER BY d.Dispute_ID DESC
        """
        
        my_disputes = db.fetch_data(query)
        
        if my_disputes.empty:
            st.info("You haven't filed any disputes.")
        else:
            for _, dispute in my_disputes.iterrows():
                status_color = "🔴" if dispute['Status'] == 'Open' else "🟡" if dispute['Status'] == 'In Progress' else "🟢"
                
                with st.expander(f"{status_color} Dispute #{int(dispute['Dispute_ID'])} - Order #{int(dispute['OrderID'])} - {dispute['Status']}"):
                    st.markdown(f"""
                    **Escrow ID:** {int(dispute['EscrowID'])}  
                    **Amount:** ${float(dispute['Amount']):.2f}  
                    **Status:** {dispute['Status']}  
                    **Filed Date:** {dispute['Open_Date']}  
                    **Resolved Date:** {dispute['Resolved_Date'] if pd.notna(dispute['Resolved_Date']) else 'Pending'}
                    """)
                    
                    st.markdown("**Description:**")
                    st.write(dispute['Description'])
                    
                    if pd.notna(dispute['Resolution_Details']):
                        st.markdown("**Resolution:**")
                        st.success(dispute['Resolution_Details'])
    
    except Exception as e:
        st.error(f"Error loading disputes: {e}")

# ==================== PROFILE ====================
def profile_page():
    st.markdown("## 👤 My Profile")
    
    user = st.session_state.logged_in_user
    users_df = db.get_all_users()
    user_data = users_df[users_df['UserID'] == user['id']].iloc[0]
    
    col1, col2 = st.columns([1, 2])
    
    with col1:
        st.markdown(f"### {user['name']}")
        st.markdown(f"**Rating:** {'⭐' * int(user['rating'])} ({user['rating']:.2f})")
        st.markdown(f"**Status:** {user['verification']}")
    
    with col2:
        st.markdown(f"**Email:** {user['email']}")
        st.markdown(f"**Phone:** {user_data['Phone_number']}")
        st.markdown(f"**Campus:** {user_data['Campus_Name']}")

# ==================== MAIN APP ====================
def main():
    # Check if user is logged in
    if st.session_state.logged_in_user is None:
        login_section()
    else:
        # Sidebar
        with st.sidebar:
            st.markdown(f"### 👋 Hello, {st.session_state.logged_in_user['name']}!")
            st.markdown(f"⭐ Rating: {st.session_state.logged_in_user['rating']:.2f}")
            st.markdown("---")
            
            # Navigation menu
            menu_options = {
                "🏠 Marketplace": "marketplace",
                "➕ Sell Item": "sell_item",
                "🛒 My Purchases": "my_purchases",
                "📊 My Listings": "my_listings",
                "💰 My Escrows": "my_escrows",
                "⚖️ My Disputes": "my_disputes",
                "👤 Profile": "profile"
            }
            
            for label, page in menu_options.items():
                if st.sidebar.button(label, use_container_width=True):
                    st.session_state.current_page = page
                    st.rerun()
            
            st.markdown("---")
            if st.sidebar.button("🚪 Logout", use_container_width=True):
                st.session_state.logged_in_user = None
                st.session_state.cart = []
                st.session_state.current_page = 'marketplace'
                st.rerun()
        
        # Main content
        if st.session_state.current_page == 'marketplace':
            marketplace_page()
        elif st.session_state.current_page == 'product_details':
            product_details_page()
        elif st.session_state.current_page == 'checkout':
            checkout_page()
        elif st.session_state.current_page == 'sell_item':
            sell_item_page()
        elif st.session_state.current_page == 'my_purchases':
            my_purchases_page()
        elif st.session_state.current_page == 'my_listings':
            my_listings_page()
        elif st.session_state.current_page == 'my_escrows':
            my_escrows_page()
        elif st.session_state.current_page == 'file_dispute':
            file_dispute_page()
        elif st.session_state.current_page == 'my_disputes':
            my_disputes_page()
        elif st.session_state.current_page == 'profile':
            profile_page()

if __name__ == "__main__":
    main()