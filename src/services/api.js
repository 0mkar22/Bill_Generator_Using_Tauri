import axios from 'axios';


const API = axios.create({ baseURL: 'http://localhost:5000/api' });

export const createWorkOrder = (workOrderData) => API.post('/workorders', workOrderData);
export const getWorkOrders = () => API.get('/workOrders');
export const deleteWorkOrder = (id) => API.delete(`/workOrders/${id}`); // <-- ADD THIS LINE

export default API;