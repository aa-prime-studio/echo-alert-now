
export interface SignalMessage {
  id: string;
  type: 'safe' | 'supplies' | 'medical' | 'danger';
  timestamp: number;
  deviceName: string;
  location?: { lat: number; lng: number; accuracy?: number };
  distance?: number;
}

export class WebRTCService {
  private peerConnection: RTCPeerConnection | null = null;
  private dataChannel: RTCDataChannel | null = null;
  private onMessageCallback: ((message: SignalMessage) => void) | null = null;
  private onConnectionStateChange: ((state: string) => void) | null = null;
  private currentLocation: { lat: number; lng: number } | null = null;

  constructor() {
    this.initializePeerConnection();
    this.initializeLocation();
  }

  private async initializeLocation() {
    try {
      if (navigator.geolocation) {
        navigator.geolocation.getCurrentPosition(
          (position) => {
            this.currentLocation = {
              lat: position.coords.latitude,
              lng: position.coords.longitude
            };
            console.log('Location obtained:', this.currentLocation);
          },
          (error) => {
            console.warn('Location access denied, using fallback');
            // 模擬台北市中心位置
            this.currentLocation = {
              lat: 25.0330 + (Math.random() - 0.5) * 0.01,
              lng: 121.5654 + (Math.random() - 0.5) * 0.01
            };
          }
        );
      } else {
        // 瀏覽器不支援地理位置，使用模擬位置
        this.currentLocation = {
          lat: 25.0330 + (Math.random() - 0.5) * 0.01,
          lng: 121.5654 + (Math.random() - 0.5) * 0.01
        };
      }
    } catch (error) {
      console.error('Failed to get location:', error);
    }
  }

  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371e3; // 地球半徑（公尺）
    const φ1 = lat1 * Math.PI/180;
    const φ2 = lat2 * Math.PI/180;
    const Δφ = (lat2-lat1) * Math.PI/180;
    const Δλ = (lng2-lng1) * Math.PI/180;

    const a = Math.sin(Δφ/2) * Math.sin(Δφ/2) +
              Math.cos(φ1) * Math.cos(φ2) *
              Math.sin(Δλ/2) * Math.sin(Δλ/2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));

    return R * c; // 距離（公尺）
  }

  private initializePeerConnection() {
    const configuration = {
      iceServers: [
        { urls: 'stun:stun.l.google.com:19302' },
        { urls: 'stun:stun1.l.google.com:19302' }
      ]
    };

    this.peerConnection = new RTCPeerConnection(configuration);
    
    this.peerConnection.onconnectionstatechange = () => {
      if (this.peerConnection) {
        this.onConnectionStateChange?.(this.peerConnection.connectionState);
      }
    };

    this.peerConnection.ondatachannel = (event) => {
      const channel = event.channel;
      channel.onmessage = (event) => {
        try {
          const message: SignalMessage = JSON.parse(event.data);
          
          // 計算距離
          if (message.location && this.currentLocation) {
            message.distance = this.calculateDistance(
              this.currentLocation.lat,
              this.currentLocation.lng,
              message.location.lat,
              message.location.lng
            );
          }
          
          this.onMessageCallback?.(message);
        } catch (error) {
          console.error('Failed to parse message:', error);
        }
      };
    };

    this.dataChannel = this.peerConnection.createDataChannel('signals', {
      ordered: true
    });

    this.dataChannel.onopen = () => {
      console.log('Data channel opened');
    };
  }

  onMessage(callback: (message: SignalMessage) => void) {
    this.onMessageCallback = callback;
  }

  onConnectionChange(callback: (state: string) => void) {
    this.onConnectionStateChange = callback;
  }

  async sendSignal(type: SignalMessage['type'], deviceName: string, includeLocation: boolean = true) {
    const location = includeLocation && this.currentLocation ? {
      lat: this.currentLocation.lat,
      lng: this.currentLocation.lng,
      accuracy: 10 + Math.random() * 20 // 模擬 GPS 精度
    } : undefined;

    if (this.dataChannel && this.dataChannel.readyState === 'open') {
      const message: SignalMessage = {
        id: crypto.randomUUID(),
        type,
        timestamp: Date.now(),
        deviceName,
        location
      };

      this.dataChannel.send(JSON.stringify(message));
      return message;
    } else {
      // 模擬附近裝置的訊號
      const simulatedNearbyDevices = [
        { name: '救援隊-Alpha', lat: 25.0335, lng: 121.5660 },
        { name: '醫療站-02', lat: 25.0325, lng: 121.5650 },
        { name: '避難所-中山', lat: 25.0340, lng: 121.5665 },
        { name: 'Device-A1B2C3', lat: 25.0320, lng: 121.5645 }
      ];

      const randomDevice = simulatedNearbyDevices[Math.floor(Math.random() * simulatedNearbyDevices.length)];
      
      const message: SignalMessage = {
        id: crypto.randomUUID(),
        type,
        timestamp: Date.now(),
        deviceName,
        location: includeLocation ? {
          lat: randomDevice.lat + (Math.random() - 0.5) * 0.002,
          lng: randomDevice.lng + (Math.random() - 0.5) * 0.002,
          accuracy: 10 + Math.random() * 20
        } : undefined
      };

      // 計算距離
      if (message.location && this.currentLocation) {
        message.distance = this.calculateDistance(
          this.currentLocation.lat,
          this.currentLocation.lng,
          message.location.lat,
          message.location.lng
        );
      }
      
      // 模擬網路延遲
      setTimeout(() => {
        this.onMessageCallback?.(message);
      }, 500 + Math.random() * 1000);
      
      return message;
    }
  }

  async simulateNearbyConnection() {
    setTimeout(() => {
      this.onConnectionStateChange?.('connected');
    }, 1000);

    // 模擬接收到附近的訊號
    setTimeout(() => {
      const simulatedSignals = [
        { type: 'safe' as const, device: '救援隊-Alpha' },
        { type: 'medical' as const, device: '市民-B7D8' },
        { type: 'supplies' as const, device: '避難所-中山' }
      ];

      simulatedSignals.forEach((signal, index) => {
        setTimeout(() => {
          this.sendSignal(signal.type, signal.device, true);
        }, (index + 1) * 2000);
      });
    }, 3000);
  }

  disconnect() {
    if (this.dataChannel) {
      this.dataChannel.close();
    }
    if (this.peerConnection) {
      this.peerConnection.close();
    }
  }
}
