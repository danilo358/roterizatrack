import express, { type Request, type Response } from 'express';
import cors from 'cors';
import axios from 'axios';
import dotenv from 'dotenv';
import pkg from 'pg';
const { Pool } = pkg;

dotenv.config();

import { calculateDistance, getRouteDistance } from './utils.js';

const pool = new Pool({
  user: 'postgres',
  host: process.env.DB_HOST || 'db-routing',
  database: 'routing_development',
  password: 'password',
  port: 5432,
});

const initDb = async () => {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS routes (
        id UUID PRIMARY KEY,
        vehicle_id UUID,
        total_distance_km FLOAT,
        geometry JSONB,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
      CREATE TABLE IF NOT EXISTS route_stops (
        id SERIAL PRIMARY KEY,
        route_id UUID REFERENCES routes(id),
        address_id UUID,
        sequence_number INTEGER
      );
    `);
    console.log('Routing database initialized');
  } catch (e) { console.error('Db init error:', e); }
};
initDb();

const app = express();
const port = process.env.PORT || 3001;
const MANAGEMENT_SERVICE_URL = process.env.MANAGEMENT_SERVICE_URL || 'http://management-service:3000';

app.use(cors());
app.use(express.json());

interface Address {
  id: string;
  latitude: number;
  longitude: number;
  street: string;
}

app.post('/rotas/calcular', async (req: Request, res: Response) => {
  try {
    const { veiculo_id, endereco_ids, optimized } = req.body;
    const authHeader = req.headers['authorization'];

    if (!veiculo_id || !endereco_ids || !Array.isArray(endereco_ids)) {
      return res.status(400).json({ error: 'Missing veiculo_id or endereco_ids' });
    }

    const addressesResponse = await axios.get(`${MANAGEMENT_SERVICE_URL}/addresses`, {
      headers: authHeader ? { 'Authorization': authHeader } : {}
    });
    const allAddresses: Address[] = addressesResponse.data;
    
    const selectedAddresses = allAddresses.filter(addr => endereco_ids.includes(addr.id));

    let orderedStops: Address[] = [];
    let polyline: any = null;
    let actualDistanceKm = 0;
    
    if (req.body.optimized && selectedAddresses.length > 0) {
      let bestRoute: Address[] = [];
      let minTotalDistance = Infinity;

      for (let startIndex = 0; startIndex < selectedAddresses.length; startIndex++) {
        const remaining = [...selectedAddresses];
        const currentRoute: Address[] = [];
        let current = remaining.splice(startIndex, 1)[0]!;
        currentRoute.push(current);

        while (remaining.length > 0) {
          let closestIndex = 0;
          let minD = calculateDistance(Number(current.latitude), Number(current.longitude), Number(remaining[0]!.latitude), Number(remaining[0]!.longitude));
          for (let i = 1; i < remaining.length; i++) {
            const d = calculateDistance(Number(current.latitude), Number(current.longitude), Number(remaining[i]!.latitude), Number(remaining[i]!.longitude));
            if (d < minD) { minD = d; closestIndex = i; }
          }
          current = remaining.splice(closestIndex, 1)[0]!;
          currentRoute.push(current);
        }

        let improved = true;
        while (improved) {
          improved = false;
          for (let i = 0; i < currentRoute.length - 1; i++) {
            for (let j = i + 2; j < currentRoute.length; j++) {
              const p_i = currentRoute[i]!;
              const p_i1 = currentRoute[i+1]!;
              const p_j = currentRoute[j]!;
              const p_j1 = currentRoute[j+1] || currentRoute[j]!;

              const d1 = calculateDistance(Number(p_i.latitude), Number(p_i.longitude), Number(p_i1.latitude), Number(p_i1.longitude)) +
                         calculateDistance(Number(p_j.latitude), Number(p_j.longitude), Number(p_j1.latitude), Number(p_j1.longitude));
              
              const d2 = calculateDistance(Number(p_i.latitude), Number(p_i.longitude), Number(p_j.latitude), Number(p_j.longitude)) +
                         calculateDistance(Number(p_i1.latitude), Number(p_i1.longitude), Number(p_j1.latitude), Number(p_j1.longitude));
              
              if (d2 < d1) {
                const sub = currentRoute.splice(i + 1, j - i);
                currentRoute.splice(i + 1, 0, ...sub.reverse());
                improved = true;
              }
            }
          }
        }

        const totalD = getRouteDistance(currentRoute);
        if (totalD < minTotalDistance) {
          minTotalDistance = totalD;
          bestRoute = currentRoute;
        }
      }
      orderedStops = bestRoute;
    } else {
      orderedStops = [...selectedAddresses].sort((a, b) => Number(a.latitude) - Number(b.latitude));
    }

    if (orderedStops.length > 1) {
      try {
        const coords = orderedStops.map(s => `${s.longitude},${s.latitude}`).join(';');
        const osrmUrl = `http://router.project-osrm.org/route/v1/driving/${coords}?overview=full&geometries=geojson`;
        const osrmRes = await axios.get(osrmUrl);
        
        if (osrmRes.data.routes && osrmRes.data.routes.length > 0) {
          polyline = osrmRes.data.routes[0].geometry;
          actualDistanceKm = osrmRes.data.routes[0].distance / 1000;
        }
      } catch (osrmError) {
        console.error('OSRM API Error:', osrmError);
        actualDistanceKm = getRouteDistance(orderedStops);
      }
    }

    res.json({
      veiculo_id,
      ordered_stops: orderedStops,
      total_distance_km: actualDistanceKm || getRouteDistance(orderedStops),
      geometry: polyline
    });
  } catch (error: any) {
    console.error('Error calculating route:', error.message);
    res.status(500).json({ error: 'Failed to calculate route' });
  }
});

app.post('/rotas/atribuir', async (req: Request, res: Response) => {
  try {
    const { veiculo_id, endereco_ids, route_id, total_distance_km, geometry } = req.body;
    const authHeader = req.headers['authorization'];
    const headers = authHeader ? { 'Authorization': authHeader } : {};

    const updatePromises = endereco_ids.map((id: string, index: number) => 
      axios.patch(`${MANAGEMENT_SERVICE_URL}/addresses/${id}`, {
        address: {
          status: 'em rota',
          vehicle_id: veiculo_id,
          route_id: route_id,
          sequence_number: index + 1
        }
      }, { headers })
    );

    await Promise.all(updatePromises);

    try {
      await pool.query(
        'INSERT INTO routes (id, vehicle_id, total_distance_km, geometry) VALUES ($1, $2, $3, $4)',
        [route_id, veiculo_id, total_distance_km || 0, geometry ? JSON.stringify(geometry) : null]
      );
      
      const stopPromises = endereco_ids.map((id: string, idx: number) => 
        pool.query(
          'INSERT INTO route_stops (route_id, address_id, sequence_number) VALUES ($1, $2, $3)',
          [route_id, id, idx + 1]
        )
      );
      await Promise.all(stopPromises);
    } catch (dbError) {
      console.error('Error saving to routing DB:', dbError);
    }

    res.json({ message: 'Route assigned successfully and statuses updated' });
  } catch (error: any) {
    console.error('Error assigning route:', error.message);
    res.status(500).json({ error: 'Failed to assign route' });
  }
});

app.get('/rotas', async (req: Request, res: Response) => {
  try {
    const result = await pool.query('SELECT id, vehicle_id, total_distance_km, geometry FROM routes');
    res.json(result.rows);
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch routes' });
  }
});

app.get('/metrics', async (req: Request, res: Response) => {
  try {
    const result = await pool.query(`
      SELECT 
        vehicle_id, 
        SUM(total_distance_km) as total_km,
        COUNT(id) as total_routes
      FROM routes
      GROUP BY vehicle_id
    `);
    res.json(result.rows);
  } catch (error: any) {
    res.status(500).json({ error: 'Failed to fetch metrics' });
  }
});

app.listen(port, () => {
  console.log(`Routing Service listening at http://localhost:${port}`);
});
