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
      AdminField('fulfilment', 'Fulfilment', options: ['pickup', 'delivery']),
      AdminField(
        'zone',
        'Delivery zone',
        type: 'reference',
        reference: 'zones',
      ),
      AdminField('driver', 'Driver', type: 'reference', reference: 'drivers'),
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
    'zones',
    'Delivery zones',
    'Configure the delivery areas and fees shown at checkout.',
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
    'staff',
    'Admin accounts',
    'Only signed-in administrators can create accounts. Usernames are unique.',
    [
      AdminField('name', 'Staff name', required: true),
      AdminField('username', 'Username', required: true),
      AdminField(
        'password',
        'Password (leave blank to keep)',
        type: 'password',
      ),
      AdminField(
        'role',
        'Role',
        options: ['admin', 'manager', 'baker', 'staff'],
      ),
      AdminField('active', 'Active', type: 'bool'),
    ],
  ),
];
AdminSection sectionFor(String key) =>
    adminSections.firstWhere((s) => s.key == key);
