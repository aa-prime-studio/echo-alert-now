import React from 'react';
import { Button } from '@/components/ui/button';
import { BingoRoom } from '@/types/game';
import { useLanguage } from '@/contexts/LanguageContext';
import { Separator } from '@/components/ui/separator';

interface RoomSelectorProps {
  rooms: BingoRoom[];
  onJoinRoom: (roomId: number) => void;
}

export const RoomSelector: React.FC<RoomSelectorProps> = ({ rooms, onJoinRoom }) => {
  const { t } = useLanguage();
  
  return (
    <div className="space-y-4">
      <h3 className="text-base font-semibold text-gray-900 text-left mb-4">
        {t('select_room')}
      </h3>
      <div className="grid grid-cols-1 gap-3">
        {rooms.map((room, index) => (
          <React.Fragment key={room.id}>
            <div className="flex items-center justify-between py-2">
              <div className="flex items-center space-x-2">
                <div className="w-2 h-2 rounded-full bg-green-500"></div>
                <span className="text-sm font-medium text-gray-900">
                  {t('room')} {room.id}
                </span>
              </div>
              <div className="flex items-center space-x-2">
                <span className="text-sm text-gray-500">
                  {room.players.length}/{room.maxPlayers} {t('players_count')}
                  {room.waitingPlayers > 0 && ` +${room.waitingPlayers}`}
                </span>
                <div className="w-[120px]">
                  <Button
                    onClick={() => onJoinRoom(room.id)}
                    disabled={room.isFull && room.waitingPlayers >= 3}
                    variant={room.isFull ? "outline" : "default"}
                    className={`w-full h-[36px] ${
                      room.isFull 
                        ? "bg-[#00d66a] hover:bg-[#00c35f] text-white border-none" 
                        : "bg-[#283ee4] hover:bg-[#1d32d4] text-white border-none"
                    } flex items-center justify-center font-semibold transition-all duration-200 transform active:scale-95 rounded-xl text-xs`}
                  >
                    {room.isFull ? t('join_waiting_list') : t('join_room')}
                  </Button>
                </div>
              </div>
            </div>
            {index < rooms.length - 1 && (
              <Separator className="my-2 h-px bg-black" />
            )}
          </React.Fragment>
        ))}
      </div>
    </div>
  );
};
