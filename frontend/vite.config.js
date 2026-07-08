import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// Vite dev server config with polling enabled so file changes are detected
// correctly when the project runs inside a Docker volume mount (hot reload).
export default defineConfig({
  plugins: [react()],
  server: {
    host: '0.0.0.0',
    port: 5173,
    watch: {
      usePolling: true,
      interval: 300
    }
  }
});
