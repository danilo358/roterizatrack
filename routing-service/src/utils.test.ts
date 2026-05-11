import { calculateDistance, getRouteDistance } from './utils.js';

describe('Routing Utilities', () => {
  test('calculateDistance returns correct KM between two points', () => {
    // SP to Rio (~350km)
    const sp = { lat: -23.5505, lon: -46.6333 };
    const rj = { lat: -22.9068, lon: -43.1729 };
    
    const distance = calculateDistance(sp.lat, sp.lon, rj.lat, rj.lon);
    expect(distance).toBeGreaterThan(340);
    expect(distance).toBeLessThan(370);
  });

  test('getRouteDistance calculates total path distance', () => {
    const route = [
      { latitude: -23.5505, longitude: -46.6333 },
      { latitude: -23.5615, longitude: -46.6560 },
      { latitude: -23.5595, longitude: -46.6633 }
    ];
    
    const total = getRouteDistance(route);
    expect(total).toBeGreaterThan(0);
    expect(total).toBeLessThan(10); // They are close
  });
});
