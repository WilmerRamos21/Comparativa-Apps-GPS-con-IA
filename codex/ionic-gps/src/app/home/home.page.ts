import { CommonModule } from '@angular/common';
import { Component } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { Geolocation } from '@capacitor/geolocation';
import type {
  PermissionStatus,
  Position,
} from '@capacitor/geolocation';
import {
  IonButton,
  IonCard,
  IonCardContent,
  IonCardHeader,
  IonCardTitle,
  IonContent,
  IonHeader,
  IonIcon,
  IonItem,
  IonLabel,
  IonList,
  IonNote,
  IonSpinner,
  IonText,
  IonTitle,
  IonToolbar,
} from '@ionic/angular/standalone';
import { addIcons } from 'ionicons';
import { alertCircleOutline, locateOutline } from 'ionicons/icons';

@Component({
  selector: 'app-home',
  templateUrl: 'home.page.html',
  styleUrls: ['home.page.scss'],
  standalone: true,
  imports: [
    CommonModule,
    IonButton,
    IonCard,
    IonCardContent,
    IonCardHeader,
    IonCardTitle,
    IonContent,
    IonHeader,
    IonIcon,
    IonItem,
    IonLabel,
    IonList,
    IonNote,
    IonSpinner,
    IonText,
    IonTitle,
    IonToolbar,
  ],
})
export class HomePage {
  position?: Position;
  errorMessage = '';
  isLoading = false;
  permissionState?: PermissionStatus['location'];

  constructor() {
    addIcons({ locateOutline, alertCircleOutline });
  }

  async getCurrentLocation(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.position = undefined;

    try {
      const hasPermission = await this.ensureLocationPermission();

      if (!hasPermission) {
        this.errorMessage =
          'El permiso de ubicación fue denegado. Actívalo en Ajustes para usar el GPS.';
        return;
      }

      this.position = await Geolocation.getCurrentPosition({
        enableHighAccuracy: true,
        timeout: 15000,
        maximumAge: 0,
      });
    } catch (error) {
      this.errorMessage = this.getLocationErrorMessage(error);
    } finally {
      this.isLoading = false;
    }
  }

  private async ensureLocationPermission(): Promise<boolean> {
    if (Capacitor.getPlatform() === 'web') {
      return true;
    }

    let status: PermissionStatus = await Geolocation.checkPermissions();
    this.permissionState = status.location;

    if (status.location === 'granted') {
      return true;
    }

    if (
      status.location === 'prompt' ||
      status.location === 'prompt-with-rationale'
    ) {
      status = await Geolocation.requestPermissions({
        permissions: ['location'],
      });

      this.permissionState = status.location;
      return status.location === 'granted';
    }

    return false;
  }

  private getLocationErrorMessage(error: unknown): string {
    const normalized = this.normalizeError(error);

    switch (normalized.code) {
      case 'OS-PLUG-GLOC-0003':
      case '1':
        return 'Permiso de ubicación denegado. Revisa los permisos de la app.';
      case 'OS-PLUG-GLOC-0007':
        return 'Los servicios de ubicación están desactivados en el dispositivo.';
      case 'OS-PLUG-GLOC-0008':
        return 'El uso de ubicación está restringido para esta app.';
      case 'OS-PLUG-GLOC-0009':
        return 'No se activó la ubicación del dispositivo.';
      case 'OS-PLUG-GLOC-0010':
      case '3':
        return 'No se pudo obtener la ubicación a tiempo. Intenta de nuevo al aire libre o con mejor señal.';
      case 'OS-PLUG-GLOC-0014':
      case 'OS-PLUG-GLOC-0015':
        return 'Hay un problema con los servicios de ubicación de Google Play.';
      case 'OS-PLUG-GLOC-0016':
      case 'OS-PLUG-GLOC-0017':
      case '2':
        return 'La ubicación no está disponible. Verifica GPS, red y modo avión.';
      default:
        return normalized.message
          ? `No se pudo obtener la ubicación: ${normalized.message}`
          : 'No se pudo obtener la ubicación. Intenta nuevamente.';
    }
  }

  private normalizeError(error: unknown): { code: string; message: string } {
    if (typeof error === 'object' && error !== null) {
      const value = error as { code?: unknown; message?: unknown };

      return {
        code: String(value.code ?? ''),
        message: String(value.message ?? ''),
      };
    }

    return {
      code: '',
      message: String(error ?? ''),
    };
  }
}