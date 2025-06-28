
export interface SignalMessage {
  id: string;
  type: 'safe' | 'supplies' | 'medical' | 'danger';
  timestamp: number;
  deviceName: string;
  distance?: number;
  direction?: 'N' | 'NE' | 'E' | 'SE' | 'S' | 'SW' | 'W' | 'NW';
}

export class WebRTCService {
  private peerConnection: RTCPeerConnection | null = null;
  private dataChannel: RTCDataChannel | null = null;
  private onMessageCallback: ((message: SignalMessage) => void) | null = null;
  private onConnectionStateChange: ((state: string) => void) | null = null;

  constructor() {
    this.initializePeerConnection();
  }

  private generateRandomDistance(): number {
    // 模糊化距離：10-500 公尺
    return Math.floor(Math.random() * 490) + 10;
  }

  private generateRandomDirection(): 'N' | 'NE' | 'E' | 'SE' | 'S' | 'SW' | 'W' | 'NW' {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'] as const;
    return directions[Math.floor(Math.random() * directions.length)];
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

  async sendSignal(type: SignalMessage['type'], deviceName: string) {
    if (this.dataChannel && this.dataChannel.readyState === 'open') {
      const message: SignalMessage = {
        id: crypto.randomUUID(),
        type,
        timestamp: Date.now(),
        deviceName,
        distance: this.generateRandomDistance(),
        direction: this.generateRandomDirection()
      };

      this.dataChannel.send(JSON.stringify(message));
      return message;
    } else {
      // 模擬附近裝置的訊號
      const simulatedNearbyDevices = [
        '救援隊-Alpha',
        '醫療站-02', 
        '避難所-中山',
        'Device-A1B2C3',
        'Emergency-X7Y9',
        'Rescue-Team-B'
      ];

      const randomDevice = simulatedNearbyDevices[Math.floor(Math.random() * simulatedNearbyDevices.length)];
      
      const message: SignalMessage = {
        id: crypto.randomUUID(),
        type,
        timestamp: Date.now(),
        deviceName,
        distance: this.generateRandomDistance(),
        direction: this.generateRandomDirection()
      };
      
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
          this.sendSignal(signal.type, signal.device);
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
