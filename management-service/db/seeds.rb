# Clear existing data
Address.destroy_all
Vehicle.destroy_all
Driver.destroy_all
User.destroy_all

User.create!(email: 'admin@trackland.com', password: 'password123')

# Create Vehicles
v1 = Vehicle.create!(plate: 'BRA2E19', model: 'Fiat Fiorino', capacity: 15)
v2 = Vehicle.create!(plate: 'KLU-4022', model: 'Mercedes Sprinter', capacity: 30)
v3 = Vehicle.create!(plate: 'ABC-1234', model: 'VW Delivery', capacity: 50)
v4 = Vehicle.create!(plate: 'XYZ-9876', model: 'Iveco Daily', capacity: 25)

# Create Drivers
Driver.create!(name: 'João Silva', cpf: '123.456.789-00')
Driver.create!(name: 'Maria Oliveira', cpf: '987.654.321-11')

# Create Addresses
addresses = [
  { street: 'Avenida Paulista', number: '1000', city: 'São Paulo', state: 'SP', zip: '01310-100', latitude: -23.5615, longitude: -46.6560 },
  { street: 'Rua Augusta', number: '1500', city: 'São Paulo', state: 'SP', zip: '01412-000', latitude: -23.5595, longitude: -46.6633 },
  { street: 'Rua Oscar Freire', number: '500', city: 'São Paulo', state: 'SP', zip: '01426-001', latitude: -23.5670, longitude: -46.6660 },
  { street: 'Rua da Consolação', number: '2000', city: 'São Paulo', state: 'SP', zip: '01302-001', latitude: -23.5530, longitude: -46.6550 },
  { street: 'Alameda Santos', number: '200', city: 'São Paulo', state: 'SP', zip: '01419-000', latitude: -23.5690, longitude: -46.6480 },
  { street: 'Rua Haddock Lobo', number: '1000', city: 'São Paulo', state: 'SP', zip: '01414-001', latitude: -23.5610, longitude: -46.6660 },
  { street: 'Avenida Brigadeiro Faria Lima', number: '3000', city: 'São Paulo', state: 'SP', zip: '01451-000', latitude: -23.5860, longitude: -46.6810 },
  { street: 'Rua Amauri', number: '200', city: 'São Paulo', state: 'SP', zip: '01448-000', latitude: -23.5840, longitude: -46.6850 },
  { street: 'Avenida Rebouças', number: '1500', city: 'São Paulo', state: 'SP', zip: '05401-200', latitude: -23.5660, longitude: -46.6780 },
  { street: 'Rua Estados Unidos', number: '800', city: 'São Paulo', state: 'SP', zip: '01427-000', latitude: -23.5750, longitude: -46.6680 },
  { street: 'Rua Groenlândia', number: '1200', city: 'São Paulo', state: 'SP', zip: '01434-000', latitude: -23.5780, longitude: -46.6690 },
  { street: 'Avenida Brasil', number: '500', city: 'São Paulo', state: 'SP', zip: '01431-000', latitude: -23.5760, longitude: -46.6630 },
  { street: 'Rua Peixoto Gomide', number: '900', city: 'São Paulo', state: 'SP', zip: '01409-001', latitude: -23.5630, longitude: -46.6580 },
  { street: 'Rua Pamplona', number: '1100', city: 'São Paulo', state: 'SP', zip: '01405-001', latitude: -23.5650, longitude: -46.6540 }
]

addresses.each do |addr|
  Address.create!(addr.merge(status: 'pendente'))
end
