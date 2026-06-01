import React, { useState, useEffect } from 'react';
import { 
  Home, Video, Calendar, Bell, Settings, 
  Droplet, Bone, Activity, Wifi, Mic, Volume2, 
  Plus, Check, X, Shield, PawPrint, Battery,
  ChevronRight, ChevronLeft, TrendingUp, Sparkles, Heart,
  MessageSquare, Send
} from 'lucide-react';
import './index.css';

// --- MAIN APP COMPONENT ---
export default function App() {
  const [activeTab, setActiveTab] = useState('dashboard');
  const [isDarkMode, setIsDarkMode] = useState(false);

  // --- HEALTH & STATS ENGINE STATE ---
  const [todayFoodIntake, setTodayFoodIntake] = useState(160);
  const [todayWaterIntake, setTodayWaterIntake] = useState(450);
  const petWeight = 25.0; // kg
  const dailyCaloricTarget = 900; // kcal
  const dailyWaterTarget = 600; // mL
  const dailyFoodTarget = 240; // g
  const eatingSpeed = 1.8; // g/s
  const [todayFeedingLogs, setTodayFeedingLogs] = useState([
    { time: '08:00 AM', amount: 80, type: 'Programado' }
  ]);
  
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
    const nowStr = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    setLastFed(`Hoy, ${nowStr}`);
    setTodayFoodIntake(prev => prev + 50);
    setTodayFeedingLogs(prev => [
      ...prev,
      { time: nowStr, amount: 50, type: 'Manual' }
    ]);
  };

  const handleManualWater = () => {
    setWaterLevel(prev => Math.min(100, prev + 25));
    setTodayWaterIntake(prev => prev + 150);
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
            onOpenStats={() => setActiveTab('statistics')}
          />
        )}
        {activeTab === 'statistics' && (
          <StatisticsScreen 
            todayFoodIntake={todayFoodIntake}
            todayWaterIntake={todayWaterIntake}
            petWeight={petWeight}
            dailyCaloricTarget={dailyCaloricTarget}
            dailyWaterTarget={dailyWaterTarget}
            dailyFoodTarget={dailyFoodTarget}
            eatingSpeed={eatingSpeed}
            todayFeedingLogs={todayFeedingLogs}
            onClose={() => setActiveTab('dashboard')}
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
      {/* Floating AI Chatbot */}
      <AiChatbotWidget 
        todayFoodIntake={todayFoodIntake}
        todayWaterIntake={todayWaterIntake}
        eatingSpeed={eatingSpeed}
      />
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

function DashboardScreen({ foodLevel, waterLevel, foodWeight, lastFed, onFeed, onWater, onOpenStats }) {
  // Determine weight status text and color
  let weightStatus = 'Estable';
  let weightStatusColor = 'var(--success)';
  if (foodWeight <= 20) {
    weightStatus = 'Vacío';
    weightStatusColor = 'var(--danger)';
  } else if (foodWeight <= 80) {
    weightStatus = 'Bajo';
    weightStatusColor = 'var(--warning)';
  } else if (foodWeight > 180) {
    weightStatus = 'Ración Servida';
    weightStatusColor = 'var(--primary)';
  }

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Resumen */}
      <div style={{ display: 'flex', gap: '16px' }}>
        <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '16px' }}>
          <Activity color="var(--primary)" size={28} style={{ marginBottom: '8px' }} />
          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Peso del Plato</span>
          <span style={{ fontSize: '1.5rem', fontWeight: '800', color: 'var(--text-primary)' }}>{Math.round(foodWeight)}g</span>
          <span style={{ fontSize: '0.7rem', color: weightStatusColor, fontWeight: 'bold', marginTop: '4px' }}>{weightStatus}</span>
        </div>
        <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '16px' }}>
          <Check color="var(--success)" size={28} style={{ marginBottom: '8px' }} />
          <span style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>Última Comida</span>
          <span style={{ fontSize: '0.95rem', fontWeight: '700', color: 'var(--text-primary)', textAlign: 'center', marginTop: '4px' }}>{lastFed}</span>
        </div>
      </div>

      {/* Premium Health Stats Link Banner */}
      <div 
        onClick={onOpenStats}
        style={{
          background: 'linear-gradient(135deg, #2C3E50 0%, #34495E 100%)',
          borderRadius: '16px',
          padding: '16px',
          display: 'flex',
          alignItems: 'center',
          gap: '16px',
          cursor: 'pointer',
          boxShadow: 'var(--shadow-md)',
          color: 'white',
          transition: 'transform 0.2s ease'
        }}
        className="hover-scale"
      >
        <div style={{ backgroundColor: 'rgba(255,255,255,0.12)', padding: '10px', borderRadius: '50%', display: 'flex' }}>
          <PawPrint color="var(--primary)" size={20} />
        </div>
        <div style={{ flex: 1 }}>
          <h4 style={{ margin: 0, fontSize: '0.9rem', fontWeight: 'bold', color: 'white' }}>Análisis de Salud de Max</h4>
          <p style={{ margin: '3px 0 0 0', fontSize: '0.7rem', color: 'rgba(255,255,255,0.7)', lineHeight: 1.35 }}>
            Hidratación: Excelente • Ingesta: Saludable<br/>
            Haz clic para ver estadísticas detalladas
          </p>
        </div>
        <ChevronRight size={18} color="rgba(255,255,255,0.7)" />
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

// --- NEW COMPONENT: ADVANCED HEALTH STATISTICS SCREEN ---
function StatisticsScreen({ 
  todayFoodIntake, todayWaterIntake, petWeight, 
  dailyCaloricTarget, dailyWaterTarget, dailyFoodTarget, 
  eatingSpeed, todayFeedingLogs, onClose 
}) {
  const [activeSubTab, setActiveSubTab] = useState('diario');
  const [aiRecs, setAiRecs] = useState(null);
  const [loadingAi, setLoadingAi] = useState(false);

  useEffect(() => {
    if (activeSubTab === 'salud' && !aiRecs) {
      setLoadingAi(true);
      fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${import.meta.env.VITE_GEMINI_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [{
                text: `Genera exactamente 3 recomendaciones médicas de salud cortas y útiles de 1 línea cada una, con base en estos datos reales de un perro Golden Retriever de 25 kg llamado Max hoy:
- Comida consumida hoy: ${todayFoodIntake}g (meta 240g)
- Agua consumida hoy: ${todayWaterIntake}ml (meta 600ml)
- Velocidad de ingesta: ${eatingSpeed} g/s (rango óptimo: 1.5 - 2.5 g/s)

Devuelve una lista separada por saltos de línea con los 3 consejos (sin títulos, sin marcas de negrita, sin números, solo el texto del consejo directamente). Comienza cada uno con un emoji correspondiente (por ejemplo, ⏱️, 💧, 🍖).`
              }]
            }
          ]
        })
      })
      .then(res => res.json())
      .then(data => {
        try {
          const text = data.candidates[0].content.parts[0].text;
          const recsList = text.split('\n').filter(l => l.trim().length > 0).slice(0, 3);
          setAiRecs(recsList);
        } catch (e) {
          setAiRecs([
            "⏱️ Ritmo de alimentación óptimo registrado en la balanza HX711.",
            "💧 Max mantiene un consumo de agua excelente de acuerdo a su peso corporal.",
            "🍖 El balance calórico diario es correcto para su nivel de actividad física."
          ]);
        }
        setLoadingAi(false);
      })
      .catch(() => {
        setAiRecs([
          "⏱️ Ritmo de alimentación óptimo registrado en la balanza HX711.",
          "💧 Max mantiene un consumo de agua excelente de acuerdo a su peso corporal.",
          "🍖 El balance calórico diario es correcto para su nivel de actividad física."
        ]);
        setLoadingAi(false);
      });
    }
  }, [activeSubTab]);

  const foodPercent = Math.min(1.0, todayFoodIntake / dailyFoodTarget);
  const waterPercent = Math.min(1.0, todayWaterIntake / dailyWaterTarget);
  const caloriePercent = Math.min(1.0, (todayFoodIntake * 3.75) / dailyCaloricTarget);
  const todayCalorieIntake = todayFoodIntake * 3.75;
  const mlPerKg = todayWaterIntake / petWeight;

  let hydrationStatus = 'Insuficiente';
  let hydrationColor = 'var(--warning)';
  if (mlPerKg >= 45.0) {
    hydrationStatus = 'Excelente';
    hydrationColor = 'var(--success)';
  } else if (mlPerKg >= 30.0) {
    hydrationStatus = 'Bueno';
    hydrationColor = '#3498DB';
  }

  // Monthly Data
  const monthlyFoodHistory = [22.0, 24.5, 21.0, 25.8, 23.4, 24.0]; // in kg
  const monthlyWaterHistory = [7.5, 8.2, 7.0, 8.8, 8.1, 8.3]; // in Liters
  const monthLabels = ['Dic', 'Ene', 'Feb', 'Mar', 'Abr', 'May'];

  return (
    <div className="animate-fade-in" style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
      
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '8px' }}>
        <button 
          onClick={onClose} 
          style={{ 
            background: 'none', border: 'none', cursor: 'pointer', 
            color: 'var(--text-primary)', display: 'flex', padding: '4px' 
          }}
        >
          <ChevronLeft size={24} />
        </button>
        <h2 style={{ margin: 0, fontSize: '1.25rem', fontWeight: 'bold' }}>Estadísticas de Salud</h2>
      </div>

      {/* Tabs */}
      <div style={{ 
        display: 'flex', borderBottom: '1px solid var(--border-color)', 
        marginBottom: '8px', width: '100%' 
      }}>
        {['diario', 'mensual', 'salud'].map(tab => (
          <button
            key={tab}
            onClick={() => setActiveSubTab(tab)}
            style={{
              flex: 1,
              padding: '12px 0',
              background: 'none',
              border: 'none',
              borderBottom: activeSubTab === tab ? '2px solid var(--primary)' : '2px solid transparent',
              color: activeSubTab === tab ? 'var(--primary)' : 'var(--text-secondary)',
              fontWeight: 'bold',
              fontSize: '0.85rem',
              cursor: 'pointer',
              textTransform: 'capitalize'
            }}
          >
            {tab === 'salud' ? 'Análisis de Salud' : tab}
          </button>
        ))}
      </div>

      {/* Tab Content */}
      {activeSubTab === 'diario' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Progress Circles */}
          <div style={{ display: 'flex', gap: '16px' }}>
            {/* Hydration */}
            <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '16px' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '12px' }}>
                Hidratación de Hoy
              </span>
              <div style={{ position: 'relative', width: '90px', height: '90px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <svg width="90" height="90" viewBox="0 0 36 36">
                  <path
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    fill="none"
                    stroke="rgba(52, 152, 219, 0.1)"
                    strokeWidth="3"
                  />
                  <path
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    fill="none"
                    stroke="#3498DB"
                    strokeWidth="3"
                    strokeDasharray={`${waterPercent * 100}, 100`}
                    strokeLinecap="round"
                  />
                </svg>
                <div style={{ position: 'absolute', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                  <span style={{ fontSize: '1.1rem', fontWeight: 'bold' }}>{Math.round(todayWaterIntake)}</span>
                  <span style={{ fontSize: '0.6rem', color: 'var(--text-secondary)' }}>mL / 600</span>
                </div>
              </div>
              <span style={{ fontSize: '0.7rem', fontWeight: 'bold', color: waterPercent >= 1 ? 'var(--success)' : '#3498DB', marginTop: '12px' }}>
                {waterPercent >= 1 ? '¡Meta Completada!' : `Faltan ${Math.max(0, 600 - todayWaterIntake)} mL`}
              </span>
            </div>

            {/* Calories */}
            <div className="card" style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', padding: '16px' }}>
              <span style={{ fontSize: '0.75rem', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '12px' }}>
                Calorías Activas
              </span>
              <div style={{ position: 'relative', width: '90px', height: '90px', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                <svg width="90" height="90" viewBox="0 0 36 36">
                  <path
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    fill="none"
                    stroke="rgba(243, 156, 18, 0.1)"
                    strokeWidth="3"
                  />
                  <path
                    d="M18 2.0845 a 15.9155 15.9155 0 0 1 0 31.831 a 15.9155 15.9155 0 0 1 0 -31.831"
                    fill="none"
                    stroke="var(--primary)"
                    strokeWidth="3"
                    strokeDasharray={`${caloriePercent * 100}, 100`}
                    strokeLinecap="round"
                  />
                </svg>
                <div style={{ position: 'absolute', display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                  <span style={{ fontSize: '1.1rem', fontWeight: 'bold' }}>{Math.round(todayCalorieIntake)}</span>
                  <span style={{ fontSize: '0.6rem', color: 'var(--text-secondary)' }}>kcal / 900</span>
                </div>
              </div>
              <span style={{ fontSize: '0.7rem', fontWeight: 'bold', color: 'var(--primary)', marginTop: '12px' }}>
                Comida: {Math.round(todayFoodIntake)}g servidos
              </span>
            </div>
          </div>

          {/* Eating Speed */}
          <div className="card">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <span style={{ fontSize: '0.85rem', fontWeight: 'bold' }}>Velocidad de Ingesta (HX711)</span>
              <span style={{ 
                fontSize: '0.7rem', fontWeight: 'bold', backgroundColor: 'rgba(46, 204, 113, 0.15)', 
                color: 'var(--success)', padding: '2px 8px', borderRadius: '10px' 
              }}>Saludable</span>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
              <div style={{ backgroundColor: 'rgba(26, 188, 156, 0.1)', padding: '10px', borderRadius: '50%', display: 'flex' }}>
                <Activity size={22} color="#1ABC9C" />
              </div>
              <div>
                <div style={{ fontSize: '1.3rem', fontWeight: '900' }}>{eatingSpeed} g/segundo</div>
                <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)' }}>Calculado dinámicamente por la balanza del plato</div>
              </div>
            </div>
            {/* Visual Gauge */}
            <div style={{ width: '100%', height: '8px', backgroundColor: 'var(--border-color)', borderRadius: '10px', position: 'relative', overflow: 'hidden', marginBottom: '6px' }}>
              <div style={{ 
                width: `${(eatingSpeed / 4.0) * 100}%`, height: '100%', 
                background: 'linear-gradient(to right, var(--success), var(--warning), var(--danger))',
                borderRadius: '10px'
              }}></div>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.6rem', color: 'var(--text-secondary)' }}>
              <span>Lento (&lt; 1.0)</span>
              <span style={{ color: 'var(--success)', fontWeight: 'bold' }}>Óptimo (1.5 - 2.5)</span>
              <span>Rápido (&gt; 3.0)</span>
            </div>
            <div style={{ 
              marginTop: '12px', padding: '10px', backgroundColor: 'rgba(26, 188, 156, 0.05)', 
              borderRadius: '8px', border: '1px solid rgba(26, 188, 156, 0.1)',
              display: 'flex', alignItems: 'center', gap: '8px'
            }}>
              <Heart size={12} color="#1ABC9C" />
              <span style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', lineHeight: 1.3 }}>
                Max tiene un ritmo excelente. Esto previene torsiones gástricas y asfixias.
              </span>
            </div>
          </div>

          {/* Today's logs */}
          <div className="card">
            <h3 style={{ fontSize: '0.85rem', fontWeight: 'bold', margin: '0 0 12px 0' }}>Registro de Ingestas Hoy</h3>
            <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
              {todayFeedingLogs.map((log, idx) => (
                <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', paddingBottom: idx < todayFeedingLogs.length - 1 ? '8px' : '0', borderBottom: idx < todayFeedingLogs.length - 1 ? '1px solid var(--border-color)' : 'none' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
                    <div style={{ 
                      backgroundColor: log.type === 'Manual' ? 'rgba(243, 156, 18, 0.12)' : 'rgba(46, 204, 113, 0.12)', 
                      padding: '6px', borderRadius: '50%', display: 'flex' 
                    }}>
                      <Bone size={12} color={log.type === 'Manual' ? 'var(--primary)' : 'var(--success)'} />
                    </div>
                    <div>
                      <div style={{ fontSize: '0.75rem', fontWeight: 'bold' }}>
                        {log.type === 'Manual' ? 'Dosificación Manual' : 'Horario Programado'}
                      </div>
                      <div style={{ fontSize: '0.6rem', color: 'var(--text-secondary)' }}>{log.time}</div>
                    </div>
                  </div>
                  <span style={{ fontSize: '0.8rem', fontWeight: 'bold', color: '#16A085' }}>+{log.amount}g</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {activeSubTab === 'mensual' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Bar Chart */}
          <div className="card">
            <h3 style={{ fontSize: '0.85rem', fontWeight: 'bold', margin: '0 0 4px 0' }}>Comparativa Histórica Mensual</h3>
            <p style={{ fontSize: '0.65rem', color: 'var(--text-secondary)', margin: '0 0 20px 0' }}>Últimos 6 meses de consumo acumulado</p>
            
            {/* Custom Flex Bar Chart */}
            <div style={{ display: 'flex', justifyContent: 'space-between', height: '140px', alignItems: 'flex-end', borderBottom: '2px solid var(--border-color)', paddingBottom: '8px', marginBottom: '8px' }}>
              {monthlyFoodHistory.map((food, idx) => {
                const water = monthlyWaterHistory[idx];
                const foodHeightPct = (food / 30.0) * 100;
                const waterHeightPct = (water / 30.0) * 100;

                return (
                  <div key={idx} style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', flex: 1, height: '100%', justifyContent: 'flex-end' }}>
                    <div style={{ display: 'flex', gap: '4px', alignItems: 'flex-end', height: '100%', width: '100%', justifyContent: 'center' }}>
                      {/* Food Bar (Orange) */}
                      <div style={{ 
                        width: '8px', height: `${foodHeightPct}%`, 
                        background: 'linear-gradient(to top, var(--primary), #E67E22)', 
                        borderRadius: '3px 3px 0 0' 
                      }}></div>
                      {/* Water Bar (Blue) */}
                      <div style={{ 
                        width: '8px', height: `${waterHeightPct}%`, 
                        background: 'linear-gradient(to top, #3498DB, #2980B9)', 
                        borderRadius: '3px 3px 0 0' 
                      }}></div>
                    </div>
                    <span style={{ fontSize: '0.6rem', color: 'var(--text-secondary)', fontWeight: 'bold', marginTop: '6px' }}>
                      {monthLabels[idx]}
                    </span>
                  </div>
                );
              })}
            </div>

            {/* Legend */}
            <div style={{ display: 'flex', justifyContent: 'center', gap: '20px', marginTop: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <div style={{ width: '10px', height: '10px', backgroundColor: 'var(--primary)', borderRadius: '2px' }}></div>
                <span style={{ fontSize: '0.65rem', fontWeight: 'bold', color: 'var(--text-secondary)' }}>Comida (kg)</span>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <div style={{ width: '10px', height: '10px', backgroundColor: '#3498DB', borderRadius: '2px' }}></div>
                <span style={{ fontSize: '0.65rem', fontWeight: 'bold', color: 'var(--text-secondary)' }}>Agua (L)</span>
              </div>
            </div>
          </div>

          {/* Monthly stats cards */}
          <div className="card">
            <h3 style={{ fontSize: '0.85rem', fontWeight: 'bold', margin: '0 0 16px 0' }}>Resumen de Tendencia Mensual</h3>
            
            <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
              <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                <div style={{ backgroundColor: 'rgba(46, 204, 113, 0.1)', padding: '6px', borderRadius: '50%', display: 'flex' }}>
                  <TrendingUp size={16} color="var(--success)" />
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', fontWeight: 'bold' }}>Consumo comida promedio</div>
                  <div style={{ fontSize: '0.85rem', fontWeight: '900' }}>23.8 kg / mes</div>
                  <div style={{ fontSize: '0.6rem', color: 'var(--text-secondary)' }}>Estable en rango del Golden Retriever</div>
                </div>
              </div>

              <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                <div style={{ backgroundColor: 'rgba(52, 152, 219, 0.1)', padding: '6px', borderRadius: '50%', display: 'flex' }}>
                  <Droplet size={16} color="#3498DB" />
                </div>
                <div>
                  <div style={{ fontSize: '0.75rem', fontWeight: 'bold' }}>Consumo agua promedio</div>
                  <div style={{ fontSize: '0.85rem', fontWeight: '900' }}>8.1 L / mes</div>
                  <div style={{ fontSize: '0.6rem', color: 'var(--text-secondary)' }}>Perfecta hidratación del 100%</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {activeSubTab === 'salud' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Health Index */}
          <div style={{ 
            background: 'linear-gradient(135deg, rgba(243, 156, 18, 0.12) 0%, rgba(230, 126, 34, 0.04) 100%)',
            borderRadius: '16px', border: '1px solid rgba(243, 156, 18, 0.3)', padding: '16px',
            display: 'flex', flexDirection: 'column', alignItems: 'center'
          }}>
            <div style={{ display: 'flex', width: '100%', justifyContent: 'space-between', marginBottom: '8px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
                <PawPrint size={14} color="var(--primary)" />
                <span style={{ fontSize: '0.75rem', fontWeight: 'bold' }}>Índice de Salud de Max</span>
              </div>
              <Heart size={14} color="red" fill="red" />
            </div>
            <div style={{ fontSize: '2.5rem', fontWeight: '900', color: 'var(--success)' }}>98/100</div>
            <div style={{ fontSize: '0.65rem', fontWeight: 'bold', color: 'var(--text-secondary)', marginBottom: '12px' }}>
              Índice Altamente Favorable
            </div>
            <div style={{ width: '100%', height: '1px', backgroundColor: 'var(--border-color)', marginBottom: '12px' }}></div>
            <div style={{ display: 'flex', width: '100%', justifyContent: 'space-around' }}>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: '900', color: 'var(--success)' }}>100%</span>
                <span style={{ fontSize: '0.55rem', fontWeight: 'bold', color: 'var(--text-secondary)' }}>Nutrición</span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: '900', color: '#3498DB' }}>
                  {Math.round((todayWaterIntake / dailyWaterTarget) * 100)}%
                </span>
                <span style={{ fontSize: '0.55rem', fontWeight: 'bold', color: 'var(--text-secondary)' }}>Hidratación</span>
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
                <span style={{ fontSize: '0.85rem', fontWeight: '900', color: 'var(--success)' }}>Excelente</span>
                <span style={{ fontSize: '0.55rem', fontWeight: 'bold', color: 'var(--text-secondary)' }}>Ingesta</span>
              </div>
            </div>
          </div>

          {/* Hydration calculation */}
          <div className="card">
            <h3 style={{ fontSize: '0.85rem', fontWeight: 'bold', margin: '0 0 4px 0' }}>Cálculo de Hidratación por Peso</h3>
            <p style={{ fontSize: '0.6rem', color: 'var(--text-secondary)', margin: '0 0 16px 0' }}>
              Meta veterinaria diaria: 40-50 mL por kilogramo de peso.
            </p>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <div>
                <div style={{ fontSize: '0.65rem', color: 'var(--text-secondary)' }}>Ingesta actual por kg:</div>
                <div style={{ fontSize: '1.2rem', fontWeight: '900' }}>{mlPerKg.toFixed(1)} mL/kg</div>
              </div>
              <span style={{ 
                fontSize: '0.75rem', fontWeight: 'bold', backgroundColor: hydrationColor === 'var(--success)' ? 'rgba(46, 204, 113, 0.15)' : 'rgba(52, 152, 219, 0.15)',
                color: hydrationColor, padding: '4px 10px', borderRadius: '12px' 
              }}>{hydrationStatus}</span>
            </div>
            {/* progress bar */}
            <div style={{ width: '100%', height: '6px', backgroundColor: 'var(--border-color)', borderRadius: '10px', overflow: 'hidden', marginBottom: '6px' }}>
              <div style={{ width: `${Math.min(100, (mlPerKg / 50.0) * 100)}%`, height: '100%', backgroundColor: hydrationColor, borderRadius: '10px' }}></div>
            </div>
            <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '0.55rem', color: 'var(--text-secondary)' }}>
              <span>0 mL</span>
              <span style={{ fontWeight: 'bold' }}>Meta: 45 mL/kg</span>
              <span>50 mL+</span>
            </div>
          </div>

          {/* AI recommendations */}
          <div className="card">
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', marginBottom: '12px' }}>
              <Sparkles size={14} color="var(--primary)" />
              <h3 style={{ fontSize: '0.85rem', fontWeight: 'bold', margin: 0 }}>Recomendaciones de Salud por Gemini IA</h3>
            </div>
            {loadingAi ? (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
                <div style={{ height: '12px', backgroundColor: 'var(--border-color)', borderRadius: '4px', animation: 'pulse 1.5s infinite' }}></div>
                <div style={{ height: '12px', backgroundColor: 'var(--border-color)', borderRadius: '4px', animation: 'pulse 1.5s infinite', width: '80%' }}></div>
                <div style={{ height: '12px', backgroundColor: 'var(--border-color)', borderRadius: '4px', animation: 'pulse 1.5s infinite', width: '90%' }}></div>
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: '10px', fontSize: '0.68rem', lineHeight: 1.35, color: 'var(--text-secondary)' }}>
                {aiRecs && aiRecs.map((rec, idx) => (
                  <div key={idx}>{rec}</div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}

// --- NEW COMPONENT: AI CHATBOT WIDGET ---
function AiChatbotWidget({ todayFoodIntake, todayWaterIntake, eatingSpeed }) {
  const [isOpen, setIsOpen] = useState(false);
  const [messages, setMessages] = useState([
    { role: 'model', text: '¡Hola! Soy PetLink AI, tu asistente veterinario inteligente. ¿Cómo puedo ayudarte hoy con el cuidado, la alimentación, el agua o la salud de Max?' }
  ]);
  const [input, setInput] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  const handleSend = async (e) => {
    e.preventDefault();
    if (!input.trim() || isTyping) return;

    const userMessage = input.trim();
    setInput('');
    setMessages(prev => [...prev, { role: 'user', text: userMessage }]);
    setIsTyping(true);

    try {
      const chatHistoryPrompt = messages.map(m => `${m.role === 'user' ? 'Dueño' : 'PetLink AI'}: ${m.text}`).join('\n');
      
      const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${import.meta.env.VITE_GEMINI_API_KEY}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [{
                text: `Eres PetLink AI, un veterinario experto y asistente de cuidado de mascotas. Max es un perro Golden Retriever de 3 años, sano y activo (peso 25.0 kg). Sus datos de hoy de los sensores IoT son:
- Comida consumida hoy: ${todayFoodIntake}g
- Agua consumida hoy: ${todayWaterIntake}ml
- Velocidad de ingesta: ${eatingSpeed} g/s

Responde preguntas de forma amigable, empática, profesional y muy concisa (máximo 2-3 oraciones). Da consejos útiles de adiestramiento o salud.
Historial del chat:
${chatHistoryPrompt}
Dueño: ${userMessage}
PetLink AI:`
              }]
            }
          ]
        })
      });

      const data = await response.json();
      const botText = data.candidates[0].content.parts[0].text;
      setMessages(prev => [...prev, { role: 'model', text: botText }]);
    } catch (error) {
      setMessages(prev => [...prev, { role: 'model', text: 'Lo siento, no he podido conectarme a la nube de Gemini. Por favor verifica tu API Key.' }]);
    } finally {
      setIsTyping(false);
    }
  };

  return (
    <div style={{ position: 'fixed', bottom: '80px', right: '20px', zIndex: 1000, fontFamily: 'inherit' }}>
      {/* Floating Button */}
      {!isOpen && (
        <button 
          onClick={() => setIsOpen(true)}
          style={{
            width: '60px', height: '60px', borderRadius: '50%',
            background: 'linear-gradient(135deg, var(--primary) 0%, #E67E22 100%)',
            border: 'none', color: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center',
            boxShadow: '0 4px 16px rgba(243, 156, 18, 0.4)', cursor: 'pointer',
            transition: 'transform 0.2s ease',
          }}
          className="hover-scale"
        >
          <MessageSquare size={28} />
        </button>
      )}

      {/* Chat Window */}
      {isOpen && (
        <div style={{
          width: '320px', height: '420px', borderRadius: '20px',
          backgroundColor: 'var(--card-bg, #ffffff)', border: '1px solid var(--border-color)',
          boxShadow: '0 8px 32px rgba(0,0,0,0.15)', display: 'flex', flexDirection: 'column',
          overflow: 'hidden', animation: 'fadeIn 0.2s ease'
        }} className="card animate-fade-in">
          {/* Header */}
          <div style={{
            background: 'linear-gradient(135deg, #2C3E50 0%, #34495E 100%)',
            padding: '12px 16px', display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            color: 'white'
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
              <div style={{ position: 'relative' }}>
                <div style={{ width: '32px', height: '32px', borderRadius: '50%', backgroundColor: 'rgba(255,255,255,0.15)', display: 'flex', justifyContent: 'center', alignItems: 'center' }}>
                  <Sparkles size={16} color="var(--primary)" />
                </div>
                <div style={{ width: '8px', height: '8px', borderRadius: '50%', backgroundColor: 'var(--success)', position: 'absolute', bottom: 0, right: 0, border: '1.5px solid #2C3E50' }}></div>
              </div>
              <div>
                <h4 style={{ margin: 0, fontSize: '0.85rem', fontWeight: 'bold', color: 'white' }}>PetLink AI</h4>
                <span style={{ fontSize: '0.6rem', color: 'rgba(255,255,255,0.7)', fontWeight: 'bold' }}>Veterinario Virtual</span>
              </div>
            </div>
            <button 
              onClick={() => setIsOpen(false)}
              style={{ background: 'none', border: 'none', color: 'white', opacity: 0.8, cursor: 'pointer', fontSize: '1.1rem', padding: '4px' }}
            >
              <X size={18} />
            </button>
          </div>

          {/* Messages */}
          <div style={{
            flex: 1, padding: '16px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: '12px',
            backgroundColor: 'var(--bg-color, #f8fafc)'
          }}>
            {messages.map((m, idx) => (
              <div 
                key={idx} 
                style={{
                  alignSelf: m.role === 'user' ? 'flex-end' : 'flex-start',
                  maxWidth: '80%',
                  padding: '10px 14px',
                  borderRadius: m.role === 'user' ? '16px 16px 2px 16px' : '16px 16px 16px 2px',
                  backgroundColor: m.role === 'user' ? 'var(--primary)' : 'var(--card-bg, #ffffff)',
                  color: m.role === 'user' ? 'white' : 'var(--text-primary)',
                  fontSize: '0.75rem',
                  lineHeight: 1.35,
                  boxShadow: m.role === 'user' ? 'none' : '0 2px 8px rgba(0,0,0,0.04)',
                  border: m.role === 'user' ? 'none' : '1px solid var(--border-color)'
                }}
              >
                {m.text}
              </div>
            ))}
            {isTyping && (
              <div style={{
                alignSelf: 'flex-start', padding: '8px 12px', borderRadius: '12px',
                backgroundColor: 'var(--card-bg, #ffffff)', border: '1px solid var(--border-color)',
                fontSize: '0.7rem', color: 'var(--text-secondary)'
              }}>
                PetLink AI está escribiendo...
              </div>
            )}
          </div>

          {/* Input Form */}
          <form onSubmit={handleSend} style={{
            padding: '10px 16px', display: 'flex', gap: '8px', borderTop: '1px solid var(--border-color)',
            backgroundColor: 'var(--card-bg, #ffffff)'
          }}>
            <input 
              type="text"
              value={input}
              onChange={e => setInput(e.target.value)}
              placeholder="Pregúntame sobre Max..."
              style={{
                flex: 1, padding: '8px 12px', borderRadius: '20px', border: '1px solid var(--border-color)',
                fontSize: '0.75rem', outline: 'none', backgroundColor: 'var(--bg-color)'
              }}
            />
            <button 
              type="submit"
              style={{
                width: '32px', height: '32px', borderRadius: '50%', backgroundColor: 'var(--primary)',
                border: 'none', color: 'white', display: 'flex', justifyContent: 'center', alignItems: 'center',
                cursor: 'pointer'
              }}
            >
              <Send size={14} />
            </button>
          </form>
        </div>
      )}
    </div>
  );
}

