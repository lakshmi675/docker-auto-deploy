// This script runs automatically the first time the mongo container
// creates its data volume (mounted into /docker-entrypoint-initdb.d/).
db = db.getSiblingDB('appdb');

db.items.insertMany([
  { name: 'Sample Item 1', createdAt: new Date() },
  { name: 'Sample Item 2', createdAt: new Date() },
  { name: 'Sample Item 3', createdAt: new Date() }
]);

print('Seeded appdb.items with sample data');
