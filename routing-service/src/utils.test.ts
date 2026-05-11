import { calculateDistance } from './utils.js';

describe('Routing Utilities', () => {
  it('calculates distance between two points correctly', () => {
    // Distance between Sao Paulo and Rio (approx 350-400km)
    const sp = { lat: -23.5505, lon: -46.6333 };
    const rj = { lat: -22.9068, lon: -43.1729 };
    
    const dist = calculateDistance(sp.lat, sp.lon, rj.lat, rj.lon);
    expect(dist).toBeGreaterThan(350);
    expect(dist).toBeLessThan(450);
  });

  it('returns 0 for the same point', () => {
    const d = calculateDistance(-23, -46, -23, -46);
    expect(d).toBe(0);
  });
});
