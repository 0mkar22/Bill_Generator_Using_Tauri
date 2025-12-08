import axios from 'axios';

// CHANGE THIS: Use a relative URL. 
// Do not use 'http://localhost:5000' or your AWS IP explicitly.
const API = axios.create({ baseURL: '/api' });

// Ensure these paths match your backend routes exactly
export const createWorkOrder = (workOrderData) => API.post('/workOrders', workOrderData);
export const getWorkOrders = () => API.get('/workOrders');
export const deleteWorkOrder = (id) => API.delete(`/workOrders/${id}`);

export default API;