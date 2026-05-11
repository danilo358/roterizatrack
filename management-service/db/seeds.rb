# Clear existing data
Address.destroy_all
Vehicle.destroy_all
User.destroy_all

User.create!(email: 'admin@roterizatrack.com', password: 'password123', name: 'Administrador', role: 'admin')

# Create Drivers
Driver.create!(name: 'João Silva', cpf: '123.456.789-00')
Driver.create!(name: 'Maria Oliveira', cpf: '987.654.321-11')

# Create Vehicles
Vehicle.create!(plate: 'BRA-2E19', model: 'Fiat Fiorino', capacity: 10)
Vehicle.create!(plate: 'KLU-4022', model: 'Mercedes Sprinter', capacity: 20)
Vehicle.create!(plate: 'ABC-1234', model: 'VW Delivery', capacity: 30)
Vehicle.create!(plate: 'XYZ-9876', model: 'Iveco Daily', capacity: 40)

# Create Addresses in Campo Grande, MS
addresses = [
  { street: 'Avenida Afonso Pena', number: '2000', city: 'Campo Grande', state: 'MS', zip: '79002-074', latitude: -20.4630, longitude: -54.6120 },
  { street: 'Rua 14 de Julho', number: '1500', city: 'Campo Grande', state: 'MS', zip: '79002-331', latitude: -20.4600, longitude: -54.6150 },
  { street: 'Avenida Mato Grosso', number: '3000', city: 'Campo Grande', state: 'MS', zip: '79002-233', latitude: -20.4500, longitude: -54.6050 },
  { street: 'Rua Rui Barbosa', number: '1000', city: 'Campo Grande', state: 'MS', zip: '79004-430', latitude: -20.4650, longitude: -54.6180 },
  { street: 'Avenida Eduardo Elias Zahran', number: '1200', city: 'Campo Grande', state: 'MS', zip: '79004-000', latitude: -20.4750, longitude: -54.6080 },
  { street: 'Rua Pedro Celestino', number: '800', city: 'Campo Grande', state: 'MS', zip: '79002-371', latitude: -20.4680, longitude: -54.6130 },
  { street: 'Rua Padre João Crippa', number: '1100', city: 'Campo Grande', state: 'MS', zip: '79002-380', latitude: -20.4620, longitude: -54.6100 },
  { street: 'Avenida Fernando Corrêa da Costa', number: '900', city: 'Campo Grande', state: 'MS', zip: '79004-310', latitude: -20.4660, longitude: -54.6090 },
  { street: 'Rua Maracaju', number: '500', city: 'Campo Grande', state: 'MS', zip: '79002-214', latitude: -20.4580, longitude: -54.6160 },
  { street: 'Rua Antônio Maria Coelho', number: '1800', city: 'Campo Grande', state: 'MS', zip: '79002-220', latitude: -20.4550, longitude: -54.6110 },
  { street: 'Avenida Ceará', number: '2500', city: 'Campo Grande', state: 'MS', zip: '79020-000', latitude: -20.4450, longitude: -54.5950 },
  { street: 'Rua Bahia', number: '1400', city: 'Campo Grande', state: 'MS', zip: '79002-530', latitude: -20.4520, longitude: -54.6080 },
  { street: 'Rua José Antônio', number: '700', city: 'Campo Grande', state: 'MS', zip: '79002-400', latitude: -20.4610, longitude: -54.6060 },
  { street: 'Rua 13 de Maio', number: '2100', city: 'Campo Grande', state: 'MS', zip: '79002-351', latitude: -20.4590, longitude: -54.6140 },
  { street: 'Avenida Bandeirantes', number: '1600', city: 'Campo Grande', state: 'MS', zip: '79006-000', latitude: -20.4800, longitude: -54.6250 },
  { street: 'Rua Brilhante', number: '2200', city: 'Campo Grande', state: 'MS', zip: '79006-560', latitude: -20.4850, longitude: -54.6300 },
  { street: 'Avenida Costa e Silva', number: '1300', city: 'Campo Grande', state: 'MS', zip: '79070-000', latitude: -20.4950, longitude: -54.6150 },
  { street: 'Avenida Mascarenhas de Moraes', number: '1900', city: 'Campo Grande', state: 'MS', zip: '79011-000', latitude: -20.4400, longitude: -54.6000 },
  { street: 'Rua Joaquim Murtinho', number: '1700', city: 'Campo Grande', state: 'MS', zip: '79002-100', latitude: -20.4700, longitude: -54.5900 },
  { street: 'Avenida Gury Marques', number: '3500', city: 'Campo Grande', state: 'MS', zip: '79072-000', latitude: -20.5100, longitude: -54.5950 }
]

addresses.each do |addr|
  Address.create!(addr.merge(status: 'pendente'))
end
