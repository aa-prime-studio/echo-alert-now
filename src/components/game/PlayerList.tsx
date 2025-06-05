
import React from 'react';
import { RoomPlayer } from '@/types/game';

interface PlayerListProps {
  players: RoomPlayer[];
  deviceName: string;
}

export const PlayerList: React.FC<PlayerListProps> = ({ players, deviceName }) => {
  return (
    <div className="mb-4 p-3 bg-gray-50 rounded-lg">
      <div className="text-sm text-gray-800 mb-2">房間玩家:</div>
      <div className="grid grid-cols-2 gap-2">
        {players.map((player, index) => (
          <div key={index} className={`text-xs p-2 rounded ${
            player.name === deviceName ? 'bg-blue-100 text-blue-800' :
            player.hasWon ? 'bg-green-100 text-green-800' :
            'bg-white text-gray-700'
          }`}>
            <div className="font-medium">{player.name}</div>
            <div>{player.completedLines} 條線 {player.hasWon && '👑'}</div>
          </div>
        ))}
      </div>
    </div>
  );
};
