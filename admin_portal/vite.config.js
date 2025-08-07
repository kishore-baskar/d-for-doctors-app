import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // Listen on all addresses
    strictPort: true,
    port: 5173, // Match the port in .gitpod.yml
    // Explicitly allow all Gitpod hosts
    allowedHosts: ['.gitpod.io'],
  },
})
