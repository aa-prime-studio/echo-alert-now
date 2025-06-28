
export interface BingoScore {
  deviceName: string;
  score: number;
  timestamp: number;
  date: string;
}

export interface BingoRoom {
  id: number;
  name: string;
  players: string[];
  currentNumbers: number[];
  isActive: boolean;
}

export interface BingoCard {
  numbers: number[];
  marked: boolean[];
}

export interface RoomPlayer {
  name: string;
  completedLines: number;
  hasWon: boolean;
}

export interface RoomChatMessage {
  id: string;
  message: string;
  playerName: string;
  timestamp: number;
  isOwn?: boolean;
}
