import React, { useState, useEffect } from 'react';
import { 
  Home, Video, Calendar, Bell, Settings, 
  Droplet, Bone, Activity, Wifi, Mic, Volume2, 
  Plus, Check, X, Shield, PawPrint, Battery
} from 'lucide-react';
import './index.css';

// --- MAIN APP COMPONENT ---
export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isDarkMode, setIsDarkMode] = useState(false);
  
  // Simulated Sensor Data
  const [foodLevel, setFoodLevel] = useState(65); // %
  const [waterLevel, setWaterLevel] = useState(40); // %
  const [foodWeight, setFoodWeight] = useState(120); // g
  const [lastFed, setLastFed] = useState('Hoy, 08:30 AM');
  const [isConnected, setIsConnected] = useState(true);
  
  // Alerts / Notifications
  const [alerts, setAlerts] = useState([
    { id: 1, type: 'food_req', msg: 'Mascota pidió comida', time: '10:45 AM', status: 'pending' },
    { id: 2, type: 'bark', msg: 'Ladrido detectado', time: '10:12 AM', status: 'info' }
  ]);
  
  // Setup theme
  useEffect(() => {
    document.documentElement.setAttribute('data-theme', isDarkMode ? 'dark' : 'light');
  }, [isDarkMode]);

  // Simulation Interval (Mocking MQTT Events)
  useEffect(() => {
    const interval = setInterval(() => {
      if (!isConnected) return;
      
      // Randomly decrease levels slightly to simulate consumption
      setWaterLevel(prev => Math.max(0, prev - (Math.random() > 0.7 ? 1 : 0)));
      setFoodWeight(prev => Math.max(0, prev - (Math.random() > 0.8 ? 5 : 0)));
      
      // Randomly trigger events (very rare)
      if (Math.random() > 0.98) {
        const newAlert = {
          id: Date.now(),
          type: Math.random() > 0.5 ? 'water_req' : 'bark',
          msg: Math.random() > 0.5 ? 'Mascota pidió agua' : 'Ladrido detectado',
          time: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
          status: Math.random() > 0.5 ? 'pending' : 'info'
        };
        setAlerts(prev => [newAlert, ...prev]);
      }
    }, 3000);
    return () => clearInterval(interval);
  }, [isConnected]);

  const handleManualFeed = () => {
    setFoodLevel(prev => Math.min(100, prev + 10));
    setFoodWeight(prev => prev + 50);
    setLastFed(`Hoy, ${new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`);
  };

  const handleManualWater = () => {
    setWaterLevel(prev => Math.min(100, prev + 25));
  };

  const pendingAlertsCount = alerts.filter(a => a.status === 'pending').length;

  return (
    <div className="app-container">
      {/* Header */}
      <header className="app-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
          <PawPrint color="var(--primary)" size={28} />
          <h1 style={{ fontSize: '1.25rem', fontWeight: '800', color: 'var(--text-primary)' }}>
            PetLink
          </h1>
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <div className={`animate-pulse-indicator`} style={{ 
              width: '10px', height: '10px', borderRadius: '50%', 
              backgroundColor: isConnected ? 'var(--success)' : 'var(--danger)' 
            }}></div>
            <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)', fontWeight: 'bold' }}>
              {isConnected ? 'ONLINE' : 'OFFLINE'}
            </span>
          </div>
          <img 
            src={`https://api.dicebear.com/7.x/notionists/svg?seed=Max&backgroundColor=F39C12`} 
            alt="Profile" 
            style={{ width: '36px', height: '36px', borderRadius: '50%', border: '2px solid var(--border-color)' }}
          />
        </div>
      </header>

      {/* Main Content Area */}
      <main className="app-content">
        {activeTab === 'dashboard' && (
          <DashboardScreen 
            foodLevel={foodLevel} waterLevel={waterLevel} foodWeight={foodWeight}
            lastFed={lastFed} onFeed={handleManualFeed} onWater={handleManualWater}
          />
        )}
        {activeTab === 'camera' && <CameraScreen />}
        {activeTab === 'schedule' && <ScheduleScreen />}
        {activeTab === 'alerts' && <AlertsScreen alerts={alerts} setAlerts={setAlerts} />}
        {activeTab === 'config' && (
          <ConfigScreen isDarkMode={isDarkMode} setIsDarkMode={setIsDarkMode} />
        )}
      </main>

      {/* Bottom Navigation */}
      <nav className="bottom-nav">
        <NavItem icon={<Home />} label="Inicio" isActive={activeTab === 'dashboard'} onClick={() => setActiveTab('dashboard')} />
        <NavItem icon={<Video />} label="Cámara" isActive={activeTab === 'camera'} onClick={() => setActiveTab('camera')} />
        <NavItem icon={<Calendar />} label="Horarios" isActive={activeTab === 'schedule'} onClick={() => setActiveTab('schedule')} />
        <NavItem icon={<Bell />} label="Alertas" isActive={activeTab === 'alerts'} onClick={() => setActiveTab('alerts')} badge={pendingAlertsCount} />
        <NavItem icon={<Settings />} label="Config" isActive={activeTab === 'config'} onClick={() => setActiveTab('config')} />
      </nav>
    </div>
  );
}

// --- SUBCOMPONENTS ---

function NavItem({ icon, label, isActive, onClick, badge }) {
  return (
    <button className={`nav-item ${isActive ? 'active' : ''}`} onClick={onClick}>
      <div className="nav-icon" style={{ position: 'relative' }}>
        {React.cloneElement(icon, { size: 24, strokeWidth: isActive ? 2.5 : 2 })}
        {badge > 0 && <span className="badge">{badge}</span>}
      </div>
      <span className="nav-label">{label}</span>
    </button>
  );
}

function ProgressBar({ value, color, icon }) {
  // Determine color based on value if specific color not provided
  const barColor = value > 50 ? 'var(--success)' : value > 20 ? 'var(--warning)' : 'var(--danger)';
  
  return (
    <div style={{ width: '100%' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '4px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
          {icon}
          <span style={{ fontWeight: 'bold', fontSize: '0.9rem' }}>Nivel</span>
        </div>
        <span style={{ fontWeight: 'bold', fontSize: '0.9rem', color: barColor }}>{Math.round(value)}%</span>
      </div>
      <div className="progress-container">
        <div className="progress-bar" style={{ width: `${value}%`, backgroundColor: color || barColor }}></div>
      </div>
    </div>
  );
}

// --- SCREENS ---

function DashboardScreen({ foodLevel, waterLevel, foodWeight, lastFed, onFeed, onWater }) {
  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Resumen */}
      <div style={{ display: 'flex', gap: '16px' }}>
        <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '16px' }}>
          <Activity color="var(--primary)" size={28} style={{ marginBottom: '8px' }} />
          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Peso del Plato</span>
          <span style={{ fontSize: '1.5rem', fontWeight: '800', color: 'var(--text-primary)' }}>{Math.round(foodWeight)}g</span>
        </div>
        <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '16px' }}>
          <Check color="var(--success)" size={28} style={{ marginBottom: '8px' }} />
          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Última Comida</span>
          <span style={{ fontSize: '0.95rem', fontWeight: '700', color: 'var(--text-primary)', textAlign: 'center', marginTop: '4px' }}>{lastFed}</span>
        </div>
      </div>

      {/* Contenedores */}
      <div className="card">
        <h3 style={{ marginBottom: '20px', fontSize: '1.1rem' }}>Estado de Contenedores</h3>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
          <ProgressBar value={foodLevel} icon={<Bone size={18} color="var(--primary)" />} />
          <ProgressBar value={waterLevel} icon={<Droplet size={18} color="#3498DB" />} />
        </div>
      </div>

      {/* Acciones */}
      <h3 style={{ marginTop: '8px', fontSize: '1.1rem' }}>Acciones Rápidas</h3>
      <div style={{ display: 'flex', gap: '12px' }}>
        <button className="btn" onClick={onFeed} style={{ flex: 1 }}>
          <Bone size={20} /> Alimentar
        </button>
        <button className="btn" onClick={onWater} style={{ flex: 1, backgroundColor: '#3498DB' }}>
          <Droplet size={20} /> Agua
        </button>
      </div>
    </div>
  );
}

function CameraScreen() {
  const [isTalking, setIsTalking] = useState(false);
  
  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '16px', height: '100%' }}>
      
      {/* Video Player Mock */}
      <div className="card" style={{ padding: '0', overflow: 'hidden', position: 'relative', height: '240px', backgroundColor: '#000', border: 'none' }}>
        <div style={{ position: 'absolute', top: '12px', left: '12px', display: 'flex', gap: '8px' }}>
          <div style={{ backgroundColor: 'rgba(0,0,0,0.6)', padding: '4px 8px', borderRadius: '4px', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <div className="animate-pulse-indicator" style={{ width: '8px', height: '8px', backgroundColor: 'red', borderRadius: '50%' }}></div>
            <span style={{ color: 'white', fontSize: '0.7rem', fontWeight: 'bold' }}>LIVE</span>
          </div>
          <div style={{ backgroundColor: 'rgba(0,0,0,0.6)', padding: '4px 8px', borderRadius: '4px', color: 'white', fontSize: '0.7rem', fontWeight: 'bold' }}>
            Plato: Parcialmente lleno
          </div>
        </div>
        
        <div style={{ width: '100%', height: '100%', display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', color: '#555' }}>
          <Video size={48} style={{ opacity: 0.5, marginBottom: '12px' }} />
          <span style={{ fontSize: '0.9rem', color: '#888' }}>Conectando al stream ESP32-CAM...</span>
        </div>
      </div>

      {/* Mic Status */}
      <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '16px', padding: '16px' }}>
        <div style={{ backgroundColor: 'rgba(46, 204, 113, 0.1)', padding: '12px', borderRadius: '50%' }}>
          <Volume2 color="var(--success)" size={24} />
        </div>
        <div>
          <h4 style={{ margin: 0 }}>Audio del ambiente</h4>
          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Silencioso (MAX9814)</span>
        </div>
      </div>

      {/* PTT Button */}
      <div style={{ flex: 1, display: 'flex', justifyContent: 'center', alignItems: 'center', paddingBottom: '20px' }}>
        <button 
          onMouseDown={() => setIsTalking(true)}
          onMouseUp={() => setIsTalking(false)}
          onTouchStart={() => setIsTalking(true)}
          onTouchEnd={() => setIsTalking(false)}
          style={{
            width: '140px', height: '140px',
            borderRadius: '50%',
            border: 'none',
            backgroundColor: isTalking ? 'var(--danger)' : 'var(--primary)',
            color: 'white',
            display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center',
            gap: '8px',
            boxShadow: isTalking ? '0 0 30px rgba(231, 76, 60, 0.6)' : 'var(--shadow-lg)',
            transition: 'all 0.2s ease',
            transform: isTalking ? 'scale(0.95)' : 'scale(1)',
            cursor: 'pointer'
          }}
        >
          <Mic size={48} />
          <span style={{ fontWeight: 'bold' }}>{isTalking ? 'Hablando...' : 'Mantener para hablar'}</span>
        </button>
      </div>
    </div>
  );
}

function ScheduleScreen() {
  const [schedules, setSchedules] = useState([
    { id: 1, type: 'food', time: '08:00 AM', amount: '80g', active: true },
    { id: 2, type: 'water', time: '09:00 AM', amount: 'Llenar', active: true },
    { id: 3, type: 'food', time: '18:30 PM', amount: '80g', active: false },
  ]);

  const toggleSchedule = (id) => {
    setSchedules(schedules.map(s => s.id === id ? { ...s, active: !s.active } : s));
  };

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '8px' }}>
        <h3 style={{ margin: 0 }}>Horarios Programados</h3>
        <button className="btn" style={{ width: 'auto', padding: '8px 12px', borderRadius: '20px', fontSize: '0.85rem' }}>
          <Plus size={16} /> Nuevo
        </button>
      </div>

      {schedules.map(schedule => (
        <div key={schedule.id} className="card" style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '16px', opacity: schedule.active ? 1 : 0.6 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
            <div style={{ backgroundColor: schedule.type === 'food' ? 'rgba(243, 156, 18, 0.1)' : 'rgba(52, 152, 219, 0.1)', padding: '12px', borderRadius: '12px' }}>
              {schedule.type === 'food' ? <Bone color="var(--primary)" /> : <Droplet color="#3498DB" />}
            </div>
            <div>
              <h4 style={{ margin: '0 0 4px 0', fontSize: '1.2rem' }}>{schedule.time}</h4>
              <span style={{ fontSize: '0.85rem', color: 'var(--text-secondary)', fontWeight: 'bold' }}>Porción: {schedule.amount}</span>
            </div>
          </div>
          <label className="switch">
            <input type="checkbox" checked={schedule.active} onChange={() => toggleSchedule(schedule.id)} />
            <span className="slider"></span>
          </label>
        </div>
      ))}

      <div className="card" style={{ marginTop: '16px' }}>
        <h4 style={{ margin: '0 0 16px 0' }}>Límites Diarios Prevención</h4>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
          <span style={{ color: 'var(--text-secondary)' }}>Máximo comida por día</span>
          <span style={{ fontWeight: 'bold' }}>300g</span>
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ color: 'var(--text-secondary)' }}>Dispensaciones extra perm.</span>
          <span style={{ fontWeight: 'bold' }}>2</span>
        </div>
      </div>
    </div>
  );
}

function AlertsScreen({ alerts, setAlerts }) {
  const handleResolve = (id, action) => {
    setAlerts(alerts.map(a => a.id === id ? { ...a, status: action } : a));
  };

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
      <h3 style={{ marginBottom: '8px' }}>Notificaciones Recientes</h3>
      
      {alerts.length === 0 ? (
        <div style={{ textAlign: 'center', padding: '40px 0', color: 'var(--text-secondary)' }}>
          <Bell size={48} style={{ opacity: 0.3, marginBottom: '16px' }} />
          <p>No hay alertas recientes</p>
        </div>
      ) : (
        alerts.map(alert => (
          <div key={alert.id} className="card" style={{ padding: '16px', borderLeft: alert.status === 'pending' ? '4px solid var(--primary)' : '4px solid var(--border-color)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
                {alert.type.includes('food') ? <Bone size={16} color="var(--primary)" /> : 
                 alert.type.includes('water') ? <Droplet size={16} color="#3498DB" /> : 
                 <Activity size={16} color="var(--warning)" />}
                <span style={{ fontWeight: 'bold' }}>{alert.msg}</span>
              </div>
              <span style={{ fontSize: '0.75rem', color: 'var(--text-secondary)' }}>{alert.time}</span>
            </div>
            
            {alert.status === 'pending' && (
              <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                <button className="btn btn-success" style={{ flex: 1, padding: '8px', fontSize: '0.85rem' }} onClick={() => handleResolve(alert.id, 'resolved')}>
                  <Check size={16} /> Autorizar
                </button>
                <button className="btn btn-danger" style={{ flex: 1, padding: '8px', fontSize: '0.85rem' }} onClick={() => handleResolve(alert.id, 'denied')}>
                  <X size={16} /> Denegar
                </button>
              </div>
            )}
            {alert.status === 'resolved' && <div style={{ fontSize: '0.8rem', color: 'var(--success)', marginTop: '8px' }}>✓ Solicitud autorizada</div>}
            {alert.status === 'denied' && <div style={{ fontSize: '0.8rem', color: 'var(--danger)', marginTop: '8px' }}>✗ Solicitud denegada</div>}
          </div>
        ))
      )}
    </div>
  );
}

function ConfigScreen({ isDarkMode, setIsDarkMode }) {
  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      <div className="card" style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
        <img 
          src={`https://api.dicebear.com/7.x/notionists/svg?seed=Max&backgroundColor=F39C12`} 
          alt="Profile" 
          style={{ width: '64px', height: '64px', borderRadius: '50%', backgroundColor: 'var(--border-color)' }}
        />
        <div>
          <h2 style={{ margin: '0 0 4px 0' }}>Max</h2>
          <span style={{ color: 'var(--text-secondary)', fontSize: '0.9rem' }}>Golden Retriever • 3 años</span>
        </div>
      </div>

      <div className="card">
        <h4 style={{ margin: '0 0 16px 0', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Settings size={18} /> Ajustes Generales
        </h4>
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--border-color)' }}>
          <span>Modo Oscuro</span>
          <label className="switch">
            <input type="checkbox" checked={isDarkMode} onChange={(e) => setIsDarkMode(e.target.checked)} />
            <span className="slider"></span>
          </label>
        </div>
        
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0', borderBottom: '1px solid var(--border-color)' }}>
          <span>Umbral Alerta Comida (%)</span>
          <input type="number" defaultValue={20} style={{ width: '60px', padding: '4px', borderRadius: '4px', border: '1px solid var(--border-color)', backgroundColor: 'var(--bg-color)', color: 'var(--text-primary)' }} />
        </div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 0' }}>
          <span>Stream aut. por sonido</span>
          <label className="switch">
            <input type="checkbox" defaultChecked />
            <span className="slider"></span>
          </label>
        </div>
      </div>

      <div className="card">
        <h4 style={{ margin: '0 0 16px 0', display: 'flex', alignItems: 'center', gap: '8px' }}>
          <Wifi size={18} /> Conexión Sistema
        </h4>
        <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
          <div>
            <label style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Broker MQTT</label>
            <div style={{ padding: '8px', backgroundColor: 'var(--bg-color)', borderRadius: '6px', fontSize: '0.9rem', marginTop: '4px' }}>mqtt://broker.hivemq.com:1883</div>
          </div>
          <div>
            <label style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Dispositivo ID</label>
            <div style={{ padding: '8px', backgroundColor: 'var(--bg-color)', borderRadius: '6px', fontSize: '0.9rem', marginTop: '4px' }}>ESP8266_UTEC_2026</div>
          </div>
        </div>
      </div>
      
      <p style={{ textAlign: 'center', fontSize: '0.75rem', color: 'var(--text-secondary)', marginTop: '20px' }}>
        PetLink v1.0.0 (UTEC 2026)<br/>
        Conectado vía WebSocket
      </p>
    </div>
  );
}
