import streamlit as st
import pandas as pd
from database import DatabaseManager
from datetime import datetime, date, time

# ==================== PAGE CONFIGURATION ====================
st.set_page_config(
    page_title="Campus Marketplace",
    page_icon="🎓",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ==================== INITIALIZE DATABASE ====================
@st.cache_resource
def get_db_manager():
    return DatabaseManager()

db = get_db_manager()

# ==================== SESSION STATE INITIALIZATION ====================
if 'logged_in_user' not in st.session_state:
    st.session_state.logged_in_user = None
if 'current_page' not in st.session_state:
    st.session_state.current_page = 'marketplace'
if 'selected_product' not in st.session_state:
    st.session_state.selected_product = None
if 'cart' not in st.session_state:
    st.session_state.cart = {}
if 'order_created' not in st.session_state:
    st.session_state.order_created = None
if 'verification_code' not in st.session_state:
    st.session_state.verification_code = None

# ==================== DARK THEME WITH MONGODB GREEN ====================
st.markdown("""
    <style>
    /* Main background */
    .stApp {
        background-color: #1e1e1e;
        color: #ffffff;
    }
    
    /* Sidebar */
    [data-testid="stSidebar"] {
        background-color: #2d2d2d;
    }
    
    /* Product cards */
    .product-card {
        border: 1px solid #3d3d3d;
        border-radius: 12px;
        padding: 20px;
        margin: 15px 0;
        background: linear-gradient(135deg, #2d2d2d 0%, #252525 100%);
        box-shadow: 0 4px 6px rgba(0, 0, 0, 0.3);
        transition: transform 0.2s, box-shadow 0.2s;
    }
    
    .product-card:hover {
        transform: translateY(-2px);
        box-shadow: 0 6px 12px rgba(0, 237, 100, 0.2);
        border-color: #00ED64;
    }
    
    .product-title {
        font-size: 1.3rem;
        font-weight: 600;
        color: #00ED64;
        margin-bottom: 8px;
    }
    
    .product-price {
        font-size: 1.8rem;
        color: #00ED64;
        font-weight: bold;
        text-shadow: 0 0 10px rgba(0, 237, 100, 0.3);
    }
    
    .seller-info {
        color: #b0b0b0;
        font-size: 0.95rem;
        margin-top: 10px;
    }
    
    .main-header {
        font-size: 2.5rem;
        font-weight: bold;
        color: #00ED64;
        text-align: center;
        padding: 30px 0;
        text-shadow: 0 0 20px rgba(0, 237, 100, 0.3);
    }
    
    /* Verification code display */
    .verification-code-box {
        background: linear-gradient(135deg, #00ED64 0%, #13aa52 100%);
        color: #1e1e1e;
        padding: 30px;
        border-radius: 15px;
        text-align: center;
        margin: 20px 0;
        box-shadow: 0 8px 16px rgba(0, 237, 100, 0.4);
        animation: pulse 2s infinite;
    }
    
    @keyframes pulse {
        0%, 100% { box-shadow: 0 8px 16px rgba(0, 237, 100, 0.4); }
        50% { box-shadow: 0 8px 24px rgba(0, 237, 100, 0.6); }
    }
    
    .verification-code-title {
        font-size: 1.2rem;
        font-weight: 600;
        margin-bottom: 15px;
    }
    
    .verification-code-number {
        font-size: 3.5rem;
        font-weight: bold;
        letter-spacing: 15px;
        font-family: 'Courier New', monospace;
        margin: 20px 0;
    }
    
    .verification-code-warning {
        font-size: 0.9rem;
        margin-top: 15px;
        opacity: 0.9;
    }
    
    /* Buttons */
    .stButton > button {
        background-color: #00ED64;
        color: #1e1e1e;
        border: none;
        border-radius: 8px;
        font-weight: 600;
        padding: 10px 24px;
        transition: all 0.3s;
    }
    
    .stButton > button:hover {
        background-color: #13aa52;
        box-shadow: 0 4px 12px rgba(0, 237, 100, 0.4);
        transform: translateY(-2px);
    }
    
    /* Input fields */
    .stTextInput > div > div > input,
    .stNumberInput > div > div > input,
    .stSelectbox > div > div > div,
    .stTextArea > div > div > textarea {
        background-color: #2d2d2d;
        color: #ffffff;
        border: 1px solid #3d3d3d;
        border-radius: 8px;
    }
    
    /* Success/Error messages */
    .stSuccess {
        background-color: rgba(0, 237, 100, 0.1);
        border: 1px solid #00ED64;
        color: #00ED64;
    }
    
    .stError {
        background-color: rgba(255, 68, 68, 0.1);
        border: 1px solid #ff4444;
        color: #ff4444;
    }
    
    .stWarning {
        background-color: rgba(255, 170, 0, 0.1);
        border: 1px solid #ffaa00;
        color: #ffaa00;
    }
    
    .stInfo {
        background-color: rgba(0, 237, 100, 0.05);
        border: 1px solid #00ED64;
        color: #b0b0b0;
    }
    
    /* Metrics */
    [data-testid="stMetricValue"] {
        color: #00ED64;
        font-size: 2rem;
    }
    
    /* Expander */
    .streamlit-expanderHeader {
        background-color: #2d2d2d;
        border-radius: 8px;
        color: #00ED64;
    }
    
    /* Tabs */
    .stTabs [data-baseweb="tab-list"] {
        gap: 8px;
    }
    
    .stTabs [data-baseweb="tab"] {
        background-color: #2d2d2d;
        color: #b0b0b0;
        border-radius: 8px 8px 0 0;
    }
    
    .stTabs [aria-selected="true"] {
        background-color: #00ED64;
        color: #1e1e1e;
    }
    
    /* Admin badge */
    .admin-badge {
        background: linear-gradient(135deg, #ff6b6b 0%, #ee5a6f 100%);
        color: white;
        padding: 5px 15px;
        border-radius: 20px;
        font-size: 0.85rem;
        font-weight: 600;
        display: inline-block;
    }
    </style>
""", unsafe_allow_html=True)

# ==================== HELPER FUNCTIONS ====================

def is_admin():
    """Check if current user is admin"""
    return st.session_state.logged_in_user and st.session_state.logged_in_user['id'] == 1

def format_currency(amount):
    """Format currency with $ symbol"""
    return f"${float(amount):.2f}"

def show_verification_code(code, order_id):
    """Display verification code prominently"""
    st.markdown(f"""
        <div class="verification-code-box">
            <div class="verification-code-title">🎉 ORDER CONFIRMED! YOUR VERIFICATION CODE:</div>
            <div class="verification-code-number">{code}</div>
            <div class="verification-code-warning">
                ⚠️ DO NOT share this code until you receive the item!<br>
                Show this code to the seller during in-person meetup.<br>
                Order ID: #{order_id}
            </div>
        </div>
    """, unsafe_allow_html=True)

# ==================== LOGIN PAGE ====================

def login_page():
    st.markdown('<p class="main-header">🎓 Campus Marketplace</p>', unsafe_allow_html=True)
    st.markdown("<h3 style='text-align: center; color: #b0b0b0;'>Secure Peer-to-Peer Trading for NEU Students</h3>", unsafe_allow_html=True)

    tab_login, tab_register = st.tabs(["🔐 Login", "🆕 Register"])

    # ==================== LOGIN TAB ====================
    with tab_login:
        st.subheader("Login to your account")

        email = st.text_input("NEU Email", placeholder="yourname@northeastern.edu", key="login_email")
        password = st.text_input("Password", type="password", placeholder="Enter your password", key="login_password")

        if st.button("🚀 Login", type="primary", use_container_width=True):
            if not email or not password:
                st.warning("Please enter both email and password.")
            else:
                user = db.authenticate_user(email.strip(), password)
                if user is None:
                    st.error("Invalid email or password.")
                else:
                    st.session_state.logged_in_user = user
                    st.session_state.current_page = 'marketplace'
                    st.success("Logged in successfully!")
                    st.rerun()

    # ==================== REGISTER TAB ====================
    with tab_register:
        st.subheader("Create a new account")

        col1, col2 = st.columns(2)

        with col1:
            reg_name = st.text_input("Full Name *", key="reg_name")
            reg_email = st.text_input("NEU Email *", placeholder="yourname@northeastern.edu", key="reg_email")
            reg_phone = st.text_input("Phone Number *", placeholder="e.g. 617-555-1234", key="reg_phone")

        with col2:
            campuses = db.get_campuses()
            if campuses.empty:
                st.error("No campuses found. Please ensure Campus table is populated.")
                reg_campus_id = None
            else:
                campus_options = {
                    row["Campus_Name"]: int(row["CampusID"])
                    for _, row in campuses.iterrows()
                }
                selected_campus_name = st.selectbox("Campus *", list(campus_options.keys()), key="reg_campus")
                reg_campus_id = campus_options[selected_campus_name] if selected_campus_name else None

            reg_password = st.text_input("Password *", type="password", key="reg_password")
            reg_confirm = st.text_input("Confirm Password *", type="password", key="reg_confirm")

        if st.button("🆕 Create Account", type="primary", use_container_width=True):
            # Basic validation
            if not reg_name or not reg_email or not reg_phone or not reg_password or not reg_confirm:
                st.warning("Please fill in all required fields.")
            elif reg_password != reg_confirm:
                st.error("Passwords do not match.")
            elif reg_campus_id is None:
                st.error("Please select a campus.")
            else:
                success, message = db.register_user(
                    name=reg_name.strip(),
                    email=reg_email.strip(),
                    phone=reg_phone.strip(),
                    password=reg_password,
                    campus_id=reg_campus_id,
                    verification_status="Verified"  # or "Pending" if you want manual approval
                )
                if success:
                    st.success(message)
                    st.info("You can now go to the Login tab and sign in.")
                else:
                    st.error(message)

# ==================== MARKETPLACE PAGE ====================

def marketplace_page():
    st.markdown("### 🏠 Campus Marketplace")
    
    # Search and filters
    col1, col2, col3 = st.columns([3, 1, 1])
    with col1:
        search_query = st.text_input("🔍 Search products", placeholder="Search by name or description...", key="search")
    with col2:
        categories = db.get_categories()
        category_filter = st.selectbox("Category", ["All"] + categories['Category_Name'].tolist())
    with col3:
        price_sort = st.selectbox("Sort by", ["Newest", "Price: Low to High", "Price: High to Low"])
    
    st.markdown("---")
    
    # Get products
    try:
        products = db.get_all_products()
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
            st.info("📦 No products found matching your criteria.")
        else:
            # Display products in grid
            cols_per_row = 3
            rows = (len(products) + cols_per_row - 1) // cols_per_row
            
            for row_idx in range(rows):
                cols = st.columns(cols_per_row)
                for col_idx in range(cols_per_row):
                    product_idx = row_idx * cols_per_row + col_idx
                    if product_idx < len(products):
                        product = products.iloc[product_idx]
                        
                        with cols[col_idx]:
                            st.markdown(f"""
                                <div class="product-card">
                                    <div class="product-title">{product['Product_Name']}</div>
                                    <div class="product-price">{format_currency(product['Unit_price'])}</div>
                                    <div class="seller-info">
                                        👤 Seller: {product['Seller']}<br>
                                        📁 Category: {product['Category_Name']}<br>
                                        📦 Available: {product['Quantity']}
                                    </div>
                                </div>
                            """, unsafe_allow_html=True)
                            
                            if st.button(f"👁️ View Details", key=f"view_{product['Product_ID']}", use_container_width=True):
                                st.session_state.selected_product = int(product['Product_ID'])
                                st.session_state.current_page = 'product_details'
                                st.rerun()
    
    except Exception as e:
        st.error(f"Error loading products: {e}")

# ==================== PRODUCT DETAILS PAGE ====================

def product_details_page():
    product_id = st.session_state.selected_product
    
    try:
        products = db.get_all_products()
        product = products[products['Product_ID'] == product_id].iloc[0]
        
        users = db.get_all_users()
        seller = users[users['User_Name'] == product['Seller']].iloc[0]
        
        if st.button("← Back to Marketplace"):
            st.session_state.current_page = 'marketplace'
            st.rerun()
        
        st.markdown("---")
        
        col1, col2 = st.columns([1, 1])
        
        with col1:
            st.markdown(f"## {product['Product_Name']}")
            st.markdown(f"<div class='product-price'>{format_currency(product['Unit_price'])}</div>", unsafe_allow_html=True)
            st.markdown(f"**Category:** {product['Category_Name']}")
            st.markdown(f"**Available Quantity:** {int(product['Quantity'])}")
            st.markdown(f"**Status:** {product['Product_Status']}")
            
            st.markdown("---")
            st.markdown("### 📝 Description")
            st.write(product['Description'])
        
        with col2:
            st.markdown("### 👤 Seller Information")
            rating_stars = '⭐' * int(seller['Agg_Seller_Rating'])
            st.info(f"""
                **Name:** {seller['User_Name']}  
                **Rating:** {rating_stars} ({seller['Agg_Seller_Rating']:.2f})  
                **Verification:** {seller['Verification_Status']}  
                **Email:** {seller['Email_ID']}  
            """)
            
            st.markdown("---")
            
            # Buy section
            if st.session_state.logged_in_user['id'] == int(seller['UserID']):
                st.warning("⚠️ This is your own listing")
            else:
                quantity = st.number_input("Quantity", min_value=1, max_value=int(product['Quantity']), value=1)
                total_price = quantity * float(product['Unit_price'])
                
                st.markdown(f"**Total Price:** {format_currency(total_price)}")
                
                if st.button("🛒 Buy Now", type="primary", use_container_width=True):
                    # Check availability before adding to cart
                    available, current_qty, msg = db.check_product_availability(int(product['Product_ID']), quantity)
                    
                    if not available:
                        st.error(f"❌ {msg}")
                    else:
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

# ==================== CHECKOUT PAGE ====================

def checkout_page():
    st.markdown("## 🛒 Order Summary")
    
    if not st.session_state.cart:
        st.warning("Your cart is empty!")
        if st.button("← Back to Marketplace"):
            st.session_state.current_page = 'marketplace'
            st.rerun()
        return
    
    cart = st.session_state.cart
    
    col1, col2 = st.columns([2, 1])
    
    with col1:
        st.markdown("### 📋 Order Details")
        st.markdown(f"""
        **Product:** {cart['product_name']}  
        **Seller:** {cart['seller_name']}  
        **Quantity:** {cart['quantity']}  
        **Price per unit:** {format_currency(cart['unit_price'])}  
        """)
        
        st.markdown("---")
        st.markdown("### 📍 Select Pickup Point")
        
        pickup_points = db.get_pickup_points(campus_id=1)
        pickup_options = {
            f"{row['Location_Name']} - {row['Street']}": int(row['PickupPointID']) 
            for _, row in pickup_points.iterrows()
        }
        
        selected_pickup = st.selectbox("Pickup Location", options=list(pickup_options.keys()))
        pickup_point_id = pickup_options[selected_pickup]
        
        st.markdown("### 📅 Schedule Pickup (Optional)")
        col_date, col_time = st.columns(2)
        with col_date:
            scheduled_date = st.date_input("Preferred Date", value=None)
        with col_time:
            scheduled_time = st.time_input("Preferred Time", value=None)
    
    with col2:
        st.markdown("### 💰 Payment Summary")
        st.markdown(f"""
        **Subtotal:** {format_currency(cart['total_price'])}  
        **Tax:** $0.00  
        **Total:** {format_currency(cart['total_price'])}
        """)
        
        st.markdown("---")
        st.info("💰 Amount will be held in escrow until delivery is confirmed")
        
        if st.button("✅ Confirm Order", type="primary", use_container_width=True):
            with st.spinner("Processing your order..."):
                try:
                    # Final availability check (race condition protection)
                    available, current_qty, msg = db.check_product_availability(
                        cart['product_id'], 
                        cart['quantity']
                    )
                    
                    if not available:
                        st.error(f"❌ {msg}")
                        st.warning("Someone else purchased this item while you were checking out. Please try again.")
                        return
                    
                    # Convert date/time to proper format
                    sched_date = scheduled_date if scheduled_date else None
                    sched_time = scheduled_time if scheduled_time else None
                    
                    # Create order using direct SQL
                    success, order_id, message = db.create_order_with_collection(
                        product_id=cart['product_id'],
                        buyer_id=st.session_state.logged_in_user['id'],
                        quantity=cart['quantity'],
                        pickup_point_id=pickup_point_id,
                        scheduled_date=sched_date,
                        scheduled_time=sched_time
                    )
                    
                    if not success:
                        st.error(f"❌ Order creation failed: {message}")
                        return
                    
                    st.info(f"✅ Order #{order_id} created successfully!")
                    
                    # Check if escrow already exists (might be created by trigger)
                    check_escrow = db.fetch_data(f"SELECT * FROM Escrow WHERE OrderID = {order_id}")
                    
                    if check_escrow.empty:
                        # Create escrow if it doesn't exist
                        escrow_success = db.add_escrow(order_id, cart['total_price'], 'Held')
                        
                        if not escrow_success:
                            st.error(f"❌ Failed to create escrow for Order #{order_id}")
                            st.error("Check terminal for detailed error message")
                            return
                    else:
                        st.info("ℹ️ Escrow already exists for this order")
                    
                    # Initiate escrow verification (generate code)
                    code_success, verification_code, code_message = db.initiate_escrow_verification(order_id)
                    
                    if not code_success:
                        st.error(f"❌ {code_message}")
                        return
                    
                    # Update product quantity
                    new_quantity = current_qty - cart['quantity']
                    new_status = 'Sold' if new_quantity == 0 else 'Active'
                    
                    update_query = f"""
                    UPDATE Product 
                    SET Quantity = {new_quantity}, 
                        Product_Status = '{new_status}'
                    WHERE Product_ID = {cart['product_id']}
                    """
                    db.execute_query(update_query)
                    
                    # Success!
                    st.success("✅ Order placed successfully!")
                    st.balloons()
                    
                    # Display verification code prominently
                    show_verification_code(verification_code, order_id)
                    
                    st.info(f"📦 Order ID: #{order_id} | {new_quantity} items remaining")
                    st.info(f"💰 Escrow Status: Held | Amount: {format_currency(cart['total_price'])}")
                    
                    # Store in session for easy retrieval
                    st.session_state.order_created = order_id
                    st.session_state.verification_code = verification_code
                    
                    # Clear cart
                    st.session_state.cart = {}
                    
                    st.markdown("---")
                    if st.button("📋 View My Orders", type="primary"):
                        st.session_state.current_page = 'my_purchases'
                        st.rerun()
                
                except Exception as e:
                    st.error(f"❌ Error processing order: {e}")
                    import traceback
                    st.code(traceback.format_exc())
    
    st.markdown("---")
    if st.button("← Cancel and go back"):
        st.session_state.cart = {}
        st.session_state.current_page = 'product_details'
        st.rerun()

# ==================== SELL ITEM PAGE ====================

def sell_item_page():
    st.markdown("## ➕ List a New Product")
    
    if st.session_state.logged_in_user['verification'] != 'Verified':
        st.error("⚠️ Only verified users can sell items. Please contact admin to verify your account.")
        return
    
    with st.form("sell_product_form"):
        col1, col2 = st.columns(2)
        
        with col1:
            product_name = st.text_input("Product Name *")
            categories = db.get_categories()
            category = st.selectbox("Category *", categories['Category_Name'].tolist())
            standard_price = st.number_input("Standard Price ($) *", min_value=0.01, value=100.0, step=0.01)
            quantity = st.number_input("Quantity *", min_value=1, value=1, step=1)
        
        with col2:
            unit_price = standard_price / quantity if quantity > 0 else standard_price
            st.markdown("### 💰 Pricing Breakdown")
            st.info(f"""
            **Standard Price:** {format_currency(standard_price)}  
            **Quantity:** {quantity}  
            **Unit Price:** {format_currency(unit_price)}  
            *(Price per item)*
            """)
        
        description = st.text_area("Description *", height=150)
        
        submitted = st.form_submit_button("📦 List Product", type="primary", use_container_width=True)
        
        if submitted:
            if product_name and description:
                category_id = int(categories[categories['Category_Name'] == category]['Category_ID'].iloc[0])
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
                    st.success(f"✅ Product listed successfully! Unit price: {format_currency(unit_price)}")
                    st.balloons()
                else:
                    st.error("❌ Failed to list product")
            else:
                st.warning("⚠️ Please fill in all required fields")

# ==================== MY PURCHASES PAGE ====================

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
            for _, order in orders.iterrows():
                with st.expander(f"Order #{int(order['OrderID'])} - {order['Product_Name']} ({format_currency(order['Amount'])})"):
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
                        **Amount:** {format_currency(order['Amount'])}  
                        **Escrow Status:** {order['Escrow_Status']}  
                        **Pickup:** {order['Pickup_Location'] if pd.notna(order['Pickup_Location']) else 'Not scheduled'}  
                        """)
                    
                    # Show verification code if escrow is held
                    if order['Escrow_Status'] == 'Held':
                        st.markdown("---")
                        verification_code = db.get_verification_code(int(order['OrderID']))
                        if verification_code:
                            show_verification_code(verification_code, int(order['OrderID']))
                    
                    # Actions
                    st.markdown("---")
                    action_col1, action_col2 = st.columns(2)
                    
                    with action_col1:
                        if order['Escrow_Status'] == 'Held':
                            if st.button(f"⚖️ File Dispute", key=f"dispute_{int(order['OrderID'])}"):
                                st.session_state.dispute_order = int(order['OrderID'])
                                st.session_state.current_page = 'file_dispute'
                                st.rerun()
                    
                    with action_col2:
                        # Rating option
                        if order['Status'] == 'Delivered' and order['Escrow_Status'] == 'Released':
                            rating_check = db.fetch_data(f"SELECT * FROM Rating WHERE Order_ID = {int(order['OrderID'])}")
                            if rating_check.empty:
                                rating = st.slider("Rate Seller", 1.0, 5.0, 5.0, 0.5, key=f"rating_{int(order['OrderID'])}")
                                if st.button(f"⭐ Submit Rating", key=f"rate_{int(order['OrderID'])}"):
                                    db.add_rating(int(order['OrderID']), user_id, int(order['Seller_ID']), float(rating))
                                    st.success("Rating submitted!")
                                    st.rerun()
    
    except Exception as e:
        st.error(f"Error loading purchases: {e}")

# ==================== MY SALES PAGE ====================

def my_sales_page():
    st.markdown("## 💼 My Sales")
    
    user_id = st.session_state.logged_in_user['id']
    
    try:
        query = f"""
        SELECT o.OrderID, p.Product_Name, buyer.User_Name as Buyer,
               o.Quantity, o.Status, o.Order_Date,
               e.EscrowID, e.Amount, e.Status as Escrow_Status,
               oc.Scheduled_Date, pp.Location_Name as Pickup_Location
        FROM [Order] o
        JOIN Product p ON o.Product_ID = p.Product_ID
        JOIN [User] buyer ON o.Buyer_ID = buyer.UserID
        LEFT JOIN Escrow e ON o.OrderID = e.OrderID
        LEFT JOIN Order_Collection oc ON o.OrderID = oc.Order_ID
        LEFT JOIN Pickup_Point pp ON oc.Pickup_Point_ID = pp.PickupPointID
        WHERE o.Seller_ID = {user_id}
        ORDER BY o.OrderID DESC
        """
        
        sales = db.fetch_data(query)
        
        if sales.empty:
            st.info("You haven't made any sales yet.")
        else:
            for _, sale in sales.iterrows():
                with st.expander(f"Order #{int(sale['OrderID'])} - {sale['Product_Name']} ({format_currency(sale['Amount'])})"):
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.markdown(f"""
                        **Product:** {sale['Product_Name']}  
                        **Buyer:** {sale['Buyer']}  
                        **Quantity:** {int(sale['Quantity'])}  
                        **Order Date:** {sale['Order_Date']}  
                        **Status:** {sale['Status']}
                        """)
                    
                    with col2:
                        st.markdown(f"""
                        **Amount:** {format_currency(sale['Amount'])}  
                        **Escrow Status:** {sale['Escrow_Status']}  
                        **Pickup:** {sale['Pickup_Location'] if pd.notna(sale['Pickup_Location']) else 'Not scheduled'}  
                        """)
                    
                    # Verification code entry for seller
                    if sale['Escrow_Status'] == 'Held':
                        st.markdown("---")
                        st.markdown("### 🔐 Complete Transaction")
                        st.info("Ask the buyer for their 6-digit verification code to complete the payment.")
                        
                        entered_code = st.text_input("Enter verification code:", max_chars=6, key=f"code_{int(sale['OrderID'])}")
                        
                        if st.button("✅ Verify & Complete Payment", key=f"verify_{int(sale['OrderID'])}"):
                            if len(entered_code) == 6:
                                success, message = db.verify_escrow_code(
                                    int(sale['OrderID']),
                                    user_id,
                                    entered_code
                                )
                                
                                if success:
                                    st.success(f"✅ {message}")
                                    st.balloons()
                                    st.rerun()
                                else:
                                    st.error(f"❌ {message}")
                            else:
                                st.warning("Please enter a 6-digit code")
    
    except Exception as e:
        st.error(f"Error loading sales: {e}")

# ==================== MY LISTINGS PAGE ====================

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
            
            for _, product in my_products.iterrows():
                with st.expander(f"{product['Product_Name']} - {format_currency(product['Unit_price'])} ({product['Product_Status']})"):
                    col1, col2 = st.columns([2, 1])
                    with col1:
                        st.markdown(f"**Category:** {product['Category_Name']}")
                        st.markdown(f"**Description:** {product['Description']}")
                        st.markdown(f"**Listed on:** {product['Created_date']}")
                    with col2:
                        st.markdown(f"**Price:** {format_currency(product['Unit_price'])}")
                        st.markdown(f"**Quantity:** {int(product['Quantity'])}")
                        st.markdown(f"**Status:** {product['Product_Status']}")
    
    except Exception as e:
        st.error(f"Error loading listings: {e}")

# ==================== FILE DISPUTE PAGE ====================

def file_dispute_page():
    st.markdown("## ⚖️ File a Dispute")
    
    if 'dispute_order' in st.session_state:
        order_id = st.session_state.dispute_order
        
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
            **Amount:** {format_currency(order['Amount'])}  
            **Escrow ID:** {int(order['EscrowID'])}
            """)
            
            with st.form("dispute_form"):
                description = st.text_area("Describe the issue *", height=200)
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
                            st.success("✅ Dispute filed successfully!")
                            del st.session_state.dispute_order
                            if st.button("View My Disputes"):
                                st.session_state.current_page = 'my_disputes'
                                st.rerun()
                        else:
                            st.error("❌ Failed to file dispute")
                    else:
                        st.warning("⚠️ Please describe the issue")
    else:
        st.warning("No order selected for dispute.")
        if st.button("← Back to My Purchases"):
            st.session_state.current_page = 'my_purchases'
            st.rerun()

# ==================== MY DISPUTES PAGE ====================

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
                status_icon = "🔴" if dispute['Status'] == 'Open' else "🟡" if dispute['Status'] == 'In Progress' else "🟢"
                
                with st.expander(f"{status_icon} Dispute #{int(dispute['Dispute_ID'])} - Order #{int(dispute['OrderID'])} - {dispute['Status']}"):
                    st.markdown(f"""
                    **Escrow ID:** {int(dispute['EscrowID'])}  
                    **Amount:** {format_currency(dispute['Amount'])}  
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

# ==================== ADMIN PANEL ====================

def admin_panel():
    st.markdown("<div class='admin-badge'>ADMIN PANEL</div>", unsafe_allow_html=True)
    st.markdown("## 🛡️ Admin Dashboard")
    
    # Dashboard stats
    stats = db.get_dashboard_stats()
    col1, col2, col3, col4, col5 = st.columns(5)
    
    with col1:
        st.metric("👥 Total Users", stats.get('total_users', 0))
    with col2:
        st.metric("📦 Active Products", stats.get('active_products', 0))
    with col3:
        st.metric("🛒 Total Orders", stats.get('total_orders', 0))
    with col4:
        st.metric("⚖️ Pending Disputes", stats.get('pending_disputes', 0))
    with col5:
        st.metric("💰 Held Escrow", format_currency(stats.get('held_escrow', 0)))
    
    st.markdown("---")
    
    # Tabs for different admin functions
    tab1, tab2, tab3 = st.tabs(["🔍 All Orders", "⚖️ Manage Disputes", "👥 User Management"])
    
    with tab1:
        st.markdown("### All Orders")
        orders = db.get_all_orders()
        if not orders.empty:
            st.dataframe(orders, use_container_width=True)
        else:
            st.info("No orders found")
    
    with tab2:
        st.markdown("### Dispute Resolution")
        disputes = db.get_all_disputes()
        
        if disputes.empty:
            st.info("No disputes found")
        else:
            # Filter by status
            status_filter = st.multiselect("Filter by Status", 
                                          options=disputes['Status'].unique(),
                                          default=['Open', 'In Progress'])
            
            filtered_disputes = disputes[disputes['Status'].isin(status_filter)]
            
            for _, dispute in filtered_disputes.iterrows():
                with st.expander(f"Dispute #{int(dispute['Dispute_ID'])} - Order #{int(dispute['OrderID'])} ({dispute['Status']})"):
                    col1, col2 = st.columns(2)
                    
                    with col1:
                        st.markdown(f"""
                        **Filed By:** {dispute['Filed_By']}  
                        **Escrow ID:** {int(dispute['EscrowID'])}  
                        **Amount:** {format_currency(dispute['Amount'])}  
                        **Status:** {dispute['Status']}  
                        **Filed Date:** {dispute['Open_Date']}
                        """)
                        
                        st.markdown("**Description:**")
                        st.write(dispute['Description'])
                    
                    with col2:
                        if dispute['Status'] in ['Open', 'In Progress']:
                            st.markdown("### 🔧 Admin Actions")
                            
                            new_status = st.selectbox("Update Status", 
                                                     ['In Progress', 'Resolved', 'Closed'],
                                                     key=f"status_{int(dispute['Dispute_ID'])}")
                            
                            resolution = st.text_area("Resolution Details", 
                                                     key=f"res_{int(dispute['Dispute_ID'])}")
                            
                            action_col1, action_col2 = st.columns(2)
                            
                            with action_col1:
                                if st.button("🔁 Refund Buyer", key=f"refund_{int(dispute['Dispute_ID'])}"):
                                    db.update_escrow_status(int(dispute['EscrowID']), 'Refunded')
                                    if resolution:
                                        db.update_dispute(int(dispute['Dispute_ID']), new_status, resolution)
                                    st.success("Refund processed!")
                                    st.rerun()
                            
                            with action_col2:
                                if st.button("💰 Release to Seller", key=f"release_{int(dispute['Dispute_ID'])}"):
                                    db.update_escrow_status(int(dispute['EscrowID']), 'Released')
                                    if resolution:
                                        db.update_dispute(int(dispute['Dispute_ID']), new_status, resolution)
                                    st.success("Payment released!")
                                    st.rerun()
                            
                            if st.button("💾 Update Dispute", key=f"update_{int(dispute['Dispute_ID'])}"):
                                if resolution:
                                    db.update_dispute(int(dispute['Dispute_ID']), new_status, resolution)
                                    st.success("Dispute updated!")
                                    st.rerun()
                        
                        else:
                            if pd.notna(dispute['Resolution_Details']):
                                st.markdown("**Resolution:**")
                                st.success(dispute['Resolution_Details'])
                                st.markdown(f"**Resolved:** {dispute['Resolved_Date']}")
    
    with tab3:
        st.markdown("### User Management")
        users = db.get_all_users()
        
        if not users.empty:
            st.dataframe(users, use_container_width=True)

# ==================== MAIN APP ====================

def main():
    if st.session_state.logged_in_user is None:
        login_page()
    else:
        # Sidebar
        with st.sidebar:
            user = st.session_state.logged_in_user
            
            if is_admin():
                st.markdown(f"<div class='admin-badge'>ADMIN</div>", unsafe_allow_html=True)
            
            st.markdown(f"### 👋 {user['name']}")
            st.markdown(f"⭐ Rating: {user['rating']:.2f}")
            st.markdown(f"✉️ {user['email']}")
            st.markdown("---")
            
            # Navigation menu
            menu_options = {
                "🏠 Marketplace": "marketplace",
                "➕ Sell Item": "sell_item",
                "🛒 My Purchases": "my_purchases",
                "💼 My Sales": "my_sales",
                "📊 My Listings": "my_listings",
                "⚖️ My Disputes": "my_disputes",
            }
            
            if is_admin():
                menu_options["🛡️ Admin Panel"] = "admin_panel"
            
            for label, page in menu_options.items():
                if st.sidebar.button(label, use_container_width=True):
                    st.session_state.current_page = page
                    st.rerun()
            
            st.markdown("---")
            if st.sidebar.button("🚪 Logout", use_container_width=True):
                st.session_state.logged_in_user = None
                st.session_state.cart = {}
                st.session_state.current_page = 'marketplace'
                st.session_state.order_created = None
                st.session_state.verification_code = None
                st.rerun()
        
        # Main content routing
        page_map = {
            'marketplace': marketplace_page,
            'product_details': product_details_page,
            'checkout': checkout_page,
            'sell_item': sell_item_page,
            'my_purchases': my_purchases_page,
            'my_sales': my_sales_page,
            'my_listings': my_listings_page,
            'file_dispute': file_dispute_page,
            'my_disputes': my_disputes_page,
            'admin_panel': admin_panel,
        }
        
        current_page = st.session_state.current_page
        if current_page in page_map:
            page_map[current_page]()
        else:
            marketplace_page()

if __name__ == "__main__":
    main()