import { Component, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import {
  IonHeader,
  IonToolbar,
  IonTitle,
  IonContent,
  IonButton,
  IonIcon,
  IonCard,
  IonCardHeader,
  IonCardTitle,
  IonCardContent,
  IonSpinner,
  IonChip,
  IonLabel,
  IonItem,
  IonList,
  ToastController,
  AlertController,
} from '@ionic/angular/standalone';
import { addIcons } from 'ionicons';
import { locate, locationOutline, alertCircleOutline, checkmarkCircleOutline, refreshOutline } from 'ionicons/icons';
import { Geolocation, Position } from '@capacitor/geolocation';

// ── Tipos internos ──────────────────────────────────────────────────────────

type AppState = 'idle' | 'loading' | 'success' | 'error';

interface GpsResult {
  latitude: number;
  longitude: number;
  accuracy: number;
  altitude: number | null;
  altitudeAccuracy: number | null;
  heading: number | null;
  speed: number | null;
  timestamp: number;
}

interface GpsError {
  code: number;
  message: string;
  suggestion: string;
}

// ── Mapeo de códigos de error de la Geolocation API ─────────────────────────

const GPS_ERROR_MAP: Record<number, { message: string; suggestion: string }> = {
  1: {
    message: 'Permiso de ubicación denegado.',
    suggestion: 'Ve a Ajustes → Privacidad → Localización y habilita el acceso para esta app.',
  },
  2: {
    message: 'Posición no disponible.',
    suggestion: 'Asegúrate de tener señal GPS o Wi-Fi activa y vuelve a intentarlo.',
  },
  3: {
    message: 'Tiempo de espera agotado.',
    suggestion: 'La señal GPS tardó demasiado. Inténtalo en un lugar con mejor cobertura.',
  },
};

const UNKNOWN_ERROR: GpsError = {
  code: -1,
  message: 'Error desconocido al obtener la ubicación.',
  suggestion: 'Reinicia la app e inténtalo de nuevo.',
};

// ── Componente ───────────────────────────────────────────────────────────────

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
  standalone: true,
  imports: [
    CommonModule,
    IonHeader,
    IonToolbar,
    IonTitle,
    IonContent,
    IonButton,
    IonIcon,
    IonCard,
    IonCardHeader,
    IonCardTitle,
    IonCardContent,
    IonSpinner,
    IonChip,
    IonLabel,
    IonItem,
    IonList,
  ],
})
export class HomePage {
  // ── Estado reactivo con signals ──────────────────────────────────────────
  readonly appState = signal<AppState>('idle');
  readonly gpsResult = signal<GpsResult | null>(null);
  readonly gpsError = signal<GpsError | null>(null);

  // ── Helpers de template ──────────────────────────────────────────────────
  get isLoading() { return this.appState() === 'loading'; }
  get isSuccess() { return this.appState() === 'success'; }
  get isError()   { return this.appState() === 'error'; }

  constructor(
    private toastCtrl: ToastController,
    private alertCtrl: AlertController,
  ) {
    addIcons({ locate, locationOutline, alertCircleOutline, checkmarkCircleOutline, refreshOutline });
  }

  // ── Acción principal ─────────────────────────────────────────────────────

  async obtenerUbicacion(): Promise<void> {
    this.appState.set('loading');
    this.gpsResult.set(null);
    this.gpsError.set(null);

    try {
      // 1️⃣ Verificar y solicitar permisos
      await this.checkAndRequestPermissions();

      // 2️⃣ Obtener posición con alta precisión
      const position: Position = await Geolocation.getCurrentPosition({
        enableHighAccuracy: true,
        timeout: 15000,        // 15 s máximo
        maximumAge: 0,         // Siempre posición fresca
      });

      // 3️⃣ Mapear resultado
      const result: GpsResult = {
        latitude:         position.coords.latitude,
        longitude:        position.coords.longitude,
        accuracy:         Math.round(position.coords.accuracy),
        altitude:         typeof position.coords.altitude === 'number' ? Math.round(position.coords.altitude) : null,
        altitudeAccuracy: typeof position.coords.altitudeAccuracy === 'number'
          ? Math.round(position.coords.altitudeAccuracy) : null,
        heading:          typeof position.coords.heading === 'number' ? position.coords.heading : null,
        speed:            typeof position.coords.speed === 'number'
          ? Math.round(position.coords.speed * 3.6 * 10) / 10 : null, // m/s → km/h
        timestamp:        position.timestamp,
      };

      this.gpsResult.set(result);
      this.appState.set('success');

      await this.showToast('✅ Ubicación obtenida correctamente', 'success');

    } catch (err: unknown) {
      const error = this.parseError(err);
      this.gpsError.set(error);
      this.appState.set('error');

      // Errores de permiso muestran alerta detallada; el resto, solo toast
      if (error.code === 1) {
        await this.showPermissionAlert(error);
      } else {
        await this.showToast(`❌ ${error.message}`, 'danger');
      }
    }
  }

  // ── Permisos ─────────────────────────────────────────────────────────────

  private async checkAndRequestPermissions(): Promise<void> {
    const status = await Geolocation.checkPermissions();

    if (status.location === 'denied') {
      throw { code: 1, message: GPS_ERROR_MAP[1].message };
    }

    if (status.location !== 'granted') {
      const request = await Geolocation.requestPermissions();
      if (request.location !== 'granted') {
        throw { code: 1, message: GPS_ERROR_MAP[1].message };
      }
    }
  }

  // ── Reintentar ────────────────────────────────────────────────────────────

  async reintentar(): Promise<void> {
    await this.obtenerUbicacion();
  }

  // ── Parseo de errores ────────────────────────────────────────────────────

  private parseError(err: unknown): GpsError {
    if (err && typeof err === 'object') {
      const e = err as { code?: number; message?: string };
      const code = e.code ?? -1;
      const mapped = GPS_ERROR_MAP[code];

      if (mapped) {
        return { code, ...mapped };
      }

      // Error sin código conocido pero con mensaje
      if (e.message) {
        return {
          code: -1,
          message: e.message,
          suggestion: UNKNOWN_ERROR.suggestion,
        };
      }
    }

    return UNKNOWN_ERROR;
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  private async showToast(message: string, color: string): Promise<void> {
    const toast = await this.toastCtrl.create({
      message,
      duration: 3000,
      color,
      position: 'bottom',
      buttons: [{ text: 'OK', role: 'cancel' }],
    });
    await toast.present();
  }

  private async showPermissionAlert(error: GpsError): Promise<void> {
    const alert = await this.alertCtrl.create({
      header: '📍 Permiso requerido',
      message: `${error.message}\n\n${error.suggestion}`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Abrir Ajustes', handler: () => { /* En iOS nativo usarías NativeSettings plugin */ } },
      ],
    });
    await alert.present();
  }

  // ── Utilidades de formato ────────────────────────────────────────────────

  formatTimestamp(ts: number): string {
    return new Date(ts).toLocaleTimeString('es-MX', {
      hour: '2-digit', minute: '2-digit', second: '2-digit',
    });
  }

  formatCoord(value: number, decimals = 6): string {
    return value.toFixed(decimals);
  }

  openInMaps(): void {
    const result = this.gpsResult();
    if (!result) { return; }
    const url = `https://maps.google.com/?q=${result.latitude},${result.longitude}`;
    window.open(url, '_blank');
  }
}
