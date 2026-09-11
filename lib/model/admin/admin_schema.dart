class AdminField {
  final String key, label, type;
  final bool required;
  final List<String> options;
  final String? reference;
  const AdminField(
    this.key,
    this.label, {
    this.type = 'text',
    this.required = false,
    this.options = const [],
    this.reference,
  });
}

class AdminSection {
  final String key, title, subtitle;
  final List<AdminField> fields;
  const AdminSection(this.key, this.title, this.subtitle, this.fields);
}

const adminSections = <AdminSection>[
  AdminSection(
    'orders',
    'Orders',
    'Phone, walk-in and online orders in one place.',
    [
      AdminField('customer', 'Customer name', required: true),
      AdminField('email', 'Customer email'),
      AdminField('phone', 'Phone'),
      AdminField('address', 'Delivery address'),
      AdminField(
        'product',
        'Cake',
        type: 'reference',
        reference: 'products',
        required: true,
      ),
      AdminField('variant', 'Variant ID (optional)'),
      AdminField('quantity', 'Quantity', type: 'integer', required: true),
      AdminField('date', 'Fulfilment date', type: 'date', required: true),
      AdminField('slot', 'Time slot', type: 'reference', reference: 'slots'),
      AdminField('fulfilment', 'Fulfilment', options: ['pickup', 'delivery']),
      AdminField(
        'zone',
        'Delivery zone',
        type: 'reference',
        reference: 'zones',
      ),
      AdminField('driver', 'Driver', type: 'reference', reference: 'drivers'),
      AdminField(
        'payment',
        'Payment method',
        options: ['cash', 'card', 'online transfer'],
      ),
      AdminField(
        'paymentStatus',
        'Payment status',
        options: ['pending', 'paid'],
      ),
      AdminField('notes', 'Instructions / allergies', type: 'multiline'),
    ],
  ),
  AdminSection(
    'products',
    'Menu',
    'Manage the customer menu. Start by adding your first cake.',
    [
      AdminField('name', 'Cake name', required: true),
      AdminField(
        'description',
        'Description',
        type: 'multiline',
        required: true,
      ),
      AdminField('price', 'Base price', type: 'number', required: true),
      AdminField(
        'category',
        'Category',
        options: ['Birthday', 'Wedding', 'Custom', 'Seasonal'],
      ),
      AdminField('tags', 'Tags (comma separated)'),
      AdminField('dietary', 'Dietary information'),
      AdminField('available', 'In stock', type: 'bool'),
      AdminField('photoData', 'Cake photo', type: 'photo'),
    ],
  ),
  AdminSection(
    'variants',
    'Cake options',
    'Each variant defines size, flavor, filling and a price adjustment.',
    [
      AdminField('name', 'Variant name', required: true),
      AdminField(
        'product',
        'Cake',
        type: 'reference',
        reference: 'products',
        required: true,
      ),
      AdminField('size', 'Size', required: true),
      AdminField('flavor', 'Flavor', required: true),
      AdminField('filling', 'Filling'),
      AdminField(
        'adjustment',
        'Price adjustment',
        type: 'signed',
        required: true,
      ),
    ],
  ),
  AdminSection(
    'requests',
    'Custom requests',
    'Design briefs, dietary needs and quotes.',
    [
      AdminField('customer', 'Customer name', required: true),
      AdminField('email', 'Email', required: true),
      AdminField('design', 'Design brief', type: 'multiline', required: true),
      AdminField('dietary', 'Dietary needs (vegan, gluten-free, allergies)'),
      AdminField('date', 'Requested date', type: 'date', required: true),
      AdminField('quote', 'Quote', type: 'number'),
      AdminField(
        'status',
        'Status',
        options: ['pending', 'quoted', 'accepted', 'declined', 'completed'],
      ),
      AdminField('notes', 'Staff notes', type: 'multiline'),
    ],
  ),
  AdminSection(
    'ingredients',
    'Inventory',
    'Stock in your chosen unit. Alerts use the reorder level.',
    [
      AdminField('name', 'Ingredient', required: true),
      AdminField('unit', 'Unit (g, kg, ml, each)', required: true),
      AdminField('stock', 'Stock on hand', type: 'number', required: true),
      AdminField(
        'minimum',
        'Low-stock threshold',
        type: 'number',
        required: true,
      ),
      AdminField(
        'supplier',
        'Supplier',
        type: 'reference',
        reference: 'suppliers',
      ),
      AdminField('cost', 'Cost per unit', type: 'number'),
    ],
  ),
  AdminSection(
    'recipes',
    'Recipes',
    'One row per ingredient per cake; stock is deducted on order creation.',
    [
      AdminField(
        'product',
        'Cake',
        type: 'reference',
        reference: 'products',
        required: true,
      ),
      AdminField(
        'ingredient',
        'Ingredient',
        type: 'reference',
        reference: 'ingredients',
        required: true,
      ),
      AdminField(
        'amount',
        'Amount per cake (ingredient unit)',
        type: 'number',
        required: true,
      ),
    ],
  ),
  AdminSection(
    'suppliers',
    'Suppliers',
    'Purchasing contacts and ingredient suppliers.',
    [
      AdminField('name', 'Supplier name', required: true),
      AdminField('contact', 'Contact person'),
      AdminField('phone', 'Phone'),
      AdminField('email', 'Email'),
      AdminField('address', 'Address'),
      AdminField('notes', 'Notes', type: 'multiline'),
    ],
  ),
  AdminSection(
    'customers',
    'Customers',
    'Profiles, delivery contacts and loyalty points.',
    [
      AdminField('name', 'Name', required: true),
      AdminField('email', 'Email', required: true),
      AdminField('phone', 'Phone'),
      AdminField('address', 'Delivery address'),
      AdminField('points', 'Loyalty points', type: 'integer'),
      AdminField('notes', 'Notes', type: 'multiline'),
    ],
  ),
  AdminSection(
    'codes',
    'Discount codes',
    'Codes are validated at customer checkout.',
    [
      AdminField('name', 'Code', required: true),
      AdminField(
        'percent',
        'Discount percent (0–100)',
        type: 'number',
        required: true,
      ),
      AdminField('minimum', 'Minimum subtotal', type: 'number'),
      AdminField('points', 'Minimum loyalty points', type: 'integer'),
      AdminField('expires', 'Expiry date (optional)', type: 'date'),
      AdminField('active', 'Active', type: 'bool'),
    ],
  ),
  AdminSection('reviews', 'Feedback', 'Customer ratings and staff replies.', [
    AdminField('customer', 'Customer name', required: true),
    AdminField('email', 'Customer email'),
    AdminField('order', 'Order ID'),
    AdminField('rating', 'Rating (1–5)', options: ['1', '2', '3', '4', '5']),
    AdminField('comment', 'Feedback', type: 'multiline', required: true),
    AdminField('reply', 'Reply', type: 'multiline'),
  ]),
  AdminSection(
    'slots',
    'Time slots',
    'Date-specific booking limits, shared by pickup and delivery.',
    [
      AdminField('name', 'Time (for example 10:00–12:00)', required: true),
      AdminField('date', 'Date', type: 'date', required: true),
      AdminField('capacity', 'Maximum orders', type: 'integer', required: true),
      AdminField('active', 'Open for bookings', type: 'bool'),
    ],
  ),
  AdminSection(
    'zones',
    'Delivery zones',
    'Delivery fees are added before tax.',
    [
      AdminField('name', 'Zone name', required: true),
      AdminField('description', 'Covered areas / postcodes'),
      AdminField('fee', 'Delivery fee', type: 'number', required: true),
      AdminField('active', 'Active', type: 'bool'),
    ],
  ),
  AdminSection(
    'drivers',
    'Drivers',
    'Assign an available driver to delivery orders.',
    [
      AdminField('name', 'Driver name', required: true),
      AdminField('phone', 'Phone', required: true),
      AdminField('vehicle', 'Vehicle / plate'),
      AdminField('active', 'Available', type: 'bool'),
    ],
  ),
  AdminSection(
    'settings',
    'Tax & capacity',
    'Explicit store settings; no jurisdiction-specific tax advice.',
    [
      AdminField('name', 'Store name', required: true),
      AdminField('tax', 'Tax percent (0–100)', type: 'number', required: true),
      AdminField(
        'capacity',
        'Maximum orders per day',
        type: 'integer',
        required: true,
      ),
      AdminField('address', 'Store address'),
      AdminField('taxId', 'Tax registration ID'),
    ],
  ),
  AdminSection(
    'staff',
    'Team & roles',
    'Owner controls access. Usernames are unique.',
    [
      AdminField('name', 'Staff name', required: true),
      AdminField('username', 'Username', required: true),
      AdminField(
        'password',
        'Password (leave blank to keep)',
        type: 'password',
      ),
      AdminField('role', 'Role', options: ['manager', 'baker', 'staff']),
      AdminField('active', 'Active', type: 'bool'),
    ],
  ),
];
AdminSection sectionFor(String key) =>
    adminSections.firstWhere((s) => s.key == key);
