
import React from 'react';
import { Button } from '@/components/ui/button';
import { BingoRoom } from '@/types/game';

interface RoomSelectorProps {
  rooms: BingoRoom[];
  onJoinRoom: (roomId: number) => void;
}

export const RoomSelector: React.FC<RoomSelectorProps> = ({ rooms, onJoinRoom }) => {
  return (
    <div>
      <h4 className="font-semibold text-gray-900 mb-3">選擇房間</h4>
      <div className="grid grid-cols-1 gap-3">
        {rooms.map((room) => (
          <Button
            key={room.id}
            variant="outline"
            className="w-full text-left justify-start"
            onClick={() => onJoinRoom(room.id)}
          >
            <div className="flex items-center justify-between w-full">
              <span>{room.name}</span>
              <span className="text-sm text-gray-500">
                {room.players.length} 玩家
              </span>
            </div>
          </Button>
        ))}
      </div>
    </div>
  );
};
