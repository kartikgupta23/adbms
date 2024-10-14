import tkinter as tk
from tkinter import ttk, messagebox
import mysql.connector
from decimal import Decimal

# MySQL connection setup
db = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database="restaurant_management"
)
cursor = db.cursor()

# Main Application Class
class RestaurantManagementSystem:
    def __init__(self, root):
        self.root = root
        self.root.title("Restaurant Management System")
        self.root.geometry("800x600")

        # Title Label
        title = tk.Label(self.root, text="Restaurant Management System", font=("Helvetica", 16, "bold"))
        title.pack(pady=20)

        # Buttons for different functionality
        tk.Button(self.root, text="Add Employee", width=25, command=self.add_employee).pack(pady=10)
        tk.Button(self.root, text="View Employees", width=25, command=self.view_employees).pack(pady=10)
        tk.Button(self.root, text="Add Menu Item", width=25, command=self.add_menu_item).pack(pady=10)
        tk.Button(self.root, text="View Menu", width=25, command=self.view_menu).pack(pady=10)
        tk.Button(self.root, text="Add Customer", width=25, command=self.add_customer).pack(pady=10)
        tk.Button(self.root, text="View Customers", width=25, command=self.view_customers).pack(pady=10)
        tk.Button(self.root, text="Create Reservation", width=25, command=self.create_reservation).pack(pady=10)

        # Additional buttons for placing orders, generating bills, viewing bills, and rating experience
        tk.Button(self.root, text="Place Order", width=25, command=self.place_order).pack(pady=10)
        tk.Button(self.root, text="Generate Bill", width=25, command=self.generate_bill).pack(pady=10)
        tk.Button(self.root, text="View Bill by Customer ID", width=25, command=self.view_bill_by_customer).pack(pady=10)
        tk.Button(self.root, text="Rate Experience", width=25, command=self.rate_experience).pack(pady=10)

    # Placeholder function for adding employees
    def add_employee(self):
        pass

    # Placeholder function for adding menu items
    def add_menu_item(self):
        pass

    # Placeholder function for adding customers
    def add_customer(self):
        pass

    # Placeholder function for creating reservations
    def create_reservation(self):
        pass

    # Function to place an order
    def place_order(self):
        order_window = tk.Toplevel(self.root)
        order_window.title("Place Order")
        order_window.geometry("400x300")

        tk.Label(order_window, text="Customer ID:").grid(row=0, column=0, pady=5)
        cID = tk.Entry(order_window)
        cID.grid(row=0, column=1)

        tk.Label(order_window, text="Menu Item ID:").grid(row=1, column=0, pady=5)
        mID = tk.Entry(order_window)
        mID.grid(row=1, column=1)

        tk.Label(order_window, text="Quantity:").grid(row=2, column=0, pady=5)
        quantity = tk.Entry(order_window)
        quantity.grid(row=2, column=1)

        def add_order():
            customer_id = cID.get()
            menu_id = mID.get()
            qty = quantity.get()

            if customer_id and menu_id and qty:
                cursor.execute("INSERT INTO orders (cid, mid, quantity) VALUES (%s, %s, %s)", (customer_id, menu_id, qty))
                db.commit()
                messagebox.showinfo("Order", "Order placed successfully!")
            else:
                messagebox.showerror("Error", "All fields are required!")

        tk.Button(order_window, text="Place Order", command=add_order).grid(row=3, column=1, pady=10)

    # Function to generate a bill for a specific customer
    def generate_bill(self):
        bill_window = tk.Toplevel(self.root)
        bill_window.title("Generate Bill")
        bill_window.geometry("400x300")

        tk.Label(bill_window, text="Customer ID:").grid(row=0, column=0, pady=5)
        cID = tk.Entry(bill_window)
        cID.grid(row=0, column=1)

        def calculate_bill():
            customer_id = cID.get()

            query = """
            SELECT M.itemName, O.quantity, M.price, C.discount
            FROM orders O
            JOIN MENU M ON O.mid = M.mid
            JOIN CUSTOMER C ON O.cid = C.cid
            WHERE O.cid = %s
            """
            cursor.execute(query, (customer_id,))
            orders = cursor.fetchall()

            if orders:
                total = Decimal(0)
                bill_details = ""
                for item_name, quantity, price, discount in orders:
                    item_total = Decimal(price) * Decimal(quantity)
                    discount_amount = item_total * Decimal(discount) / Decimal(100)
                    item_total -= discount_amount
                    total += item_total
                    bill_details += f"{item_name}: {quantity} x {price} = {item_total:.2f} (after {discount}% discount)\n"
                
                messagebox.showinfo("Bill", f"Customer ID: {customer_id}\n{bill_details}\nTotal: {total:.2f}")
            else:
                messagebox.showerror("Error", "No orders found for this customer.")

        tk.Button(bill_window, text="Calculate Bill", command=calculate_bill, width=20).grid(row=2, column=1, pady=10)

    # Function to allow customers to give ratings
    def rate_experience(self):
        rate_window = tk.Toplevel(self.root)
        rate_window.title("Rate Experience")
        rate_window.geometry("400x300")

        tk.Label(rate_window, text="Customer ID:").grid(row=0, column=0, pady=5)
        cID = tk.Entry(rate_window)
        cID.grid(row=0, column=1)

        tk.Label(rate_window, text="Rating (1-5):").grid(row=1, column=0, pady=5)
        rating_entry = tk.Entry(rate_window)
        rating_entry.grid(row=1, column=1)

        def submit_rating():
            customer_id = cID.get()
            rating = rating_entry.get()

            if customer_id and rating:
                try:
                    rating = int(rating)
                    if 1 <= rating <= 5:
                        cursor.execute("INSERT INTO RATING (cid, rating) VALUES (%s, %s)", (customer_id, rating))
                        db.commit()
                        messagebox.showinfo("Rating", "Thank you for your feedback!")
                    else:
                        messagebox.showerror("Error", "Rating must be between 1 and 5.")
                except ValueError:
                    messagebox.showerror("Error", "Please enter a valid number for the rating.")
            else:
                messagebox.showerror("Error", "All fields are required!")

        tk.Button(rate_window, text="Submit Rating", command=submit_rating, width=20).grid(row=2, column=1, pady=10)

    def view_employees(self):
        self.show_table_data("EMPLOYEE", ["Employee ID", "First Name", "Last Name", "Position", "Email"])

    def view_menu(self):
        self.show_table_data("MENU", ["Item ID", "Item Name", "Description", "Price", "Type"])

    def view_customers(self):
        self.show_table_data("CUSTOMER", ["Customer ID", "First Name", "Last Name", "Email", "Menu Item ID"])

    def view_reservations(self):
        self.show_table_data("RESERVATION", ["Reservation ID", "Table ID", "Customer ID", "Party Size", "Reservation Date"])

    def view_bill_by_customer(self):
        bill_window = tk.Toplevel(self.root)
        bill_window.title("View Bill")
        bill_window.geometry("400x300")

        tk.Label(bill_window, text="Customer ID:").grid(row=0, column=0, pady=5)
        cID = tk.Entry(bill_window)
        cID.grid(row=0, column=1)

        def view_bill():
            customer_id = cID.get()

            query = """
            SELECT M.itemName, O.quantity, M.price, C.discount
            FROM orders O
            JOIN MENU M ON O.mid = M.mid
            JOIN CUSTOMER C ON O.cid = C.cid
            WHERE O.cid = %s
            """
            cursor.execute(query, (customer_id,))
            orders = cursor.fetchall()

            if orders:
                total = Decimal(0)
                bill_details = ""
                for item_name, quantity, price, discount in orders:
                    item_total = Decimal(price) * Decimal(quantity)
                    discount_amount = item_total * Decimal(discount) / Decimal(100)
                    item_total -= discount_amount
                    total += item_total
                    bill_details += f"{item_name}: {quantity} x {price} = {item_total:.2f} (after {discount}% discount)\n"
                
                messagebox.showinfo("Bill", f"Customer ID: {customer_id}\n{bill_details}\nTotal: {total:.2f}")
            else:
                messagebox.showerror("Error", "No orders found for this customer.")

        tk.Button(bill_window, text="View Bill", command=view_bill, width=20).grid(row=2, column=1, pady=10)

    def show_table_data(self, table_name, columns):
        data_window = tk.Toplevel(self.root)
        data_window.title(f"View {table_name}")
        data_window.geometry("800x400")

        tree = ttk.Treeview(data_window, columns=columns, show='headings')
        for col in columns:
            tree.heading(col, text=col)
            tree.column(col, width=100)

        query = f"SELECT * FROM {table_name}"
        cursor.execute(query)
        records = cursor.fetchall()

        for row in records:
            tree.insert('', tk.END, values=row)

        tree.pack(fill=tk.BOTH, expand=True)

# Main loop for the application
root = tk.Tk()
app = RestaurantManagementSystem(root)
root.mainloop()

# Close the database connection when the application is closed
#db.close()
