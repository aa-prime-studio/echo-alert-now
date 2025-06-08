import React, { useState, useEffect } from 'react';
import { Grid3X3 } from 'lucide-react';
import { Button } from '@/components/ui/button';
import { toast } from 'sonner';
import { BingoCard } from '@/components/game/BingoCard';
import { RoomChat } from '@/components/game/RoomChat';
import { PlayerList } from '@/components/game/PlayerList';
import { RoomSelector } from '@/components/game/RoomSelector';
import { GameRules } from '@/components/game/GameRules';
import { Leaderboard } from '@/components/game/Leaderboard';
import { DrawnNumbers } from '@/components/game/DrawnNumbers';
import { 
  BingoScore, 
  BingoRoom, 
  BingoCard as BingoCardType, 
  RoomPlayer, 
  RoomChatMessage 
} from '@/types/game';
import { useLanguage } from '@/contexts/LanguageContext';

interface GameRoomProps {
  deviceName: string;
}

export const GameRoom: React.FC<GameRoomProps> = ({ deviceName }) => {
  const { t } = useLanguage();
  const [currentRoom, setCurrentRoom] = useState<number | null>(null);
  const [leaderboard, setLeaderboard] = useState<BingoScore[]>([]);
  const [bingoCard, setBingoCard] = useState<BingoCardType | null>(null);
  const [drawnNumbers, setDrawnNumbers] = useState<number[]>([]);
  const [completedLines, setCompletedLines] = useState(0);
  const [gameWon, setGameWon] = useState(false);
  const [roomPlayers, setRoomPlayers] = useState<RoomPlayer[]>([]);
  const [roomChatMessages, setRoomChatMessages] = useState<RoomChatMessage[]>([]);
  const [newChatMessage, setNewChatMessage] = useState('');
  const [gameEnded, setGameEnded] = useState(false);
  const [isWaiting, setIsWaiting] = useState(false);
  const [waitingPosition, setWaitingPosition] = useState<number | null>(null);

  // 3個賓果房間
  const [rooms] = useState<BingoRoom[]>([
    { 
      id: 1, 
      name: 'room A', 
      players: [], 
      currentNumbers: [], 
      isActive: false,
      maxPlayers: 6,  // 每個房間最多6個玩家
      isFull: false,
      waitingPlayers: 0
    },
    { 
      id: 2, 
      name: 'room B', 
      players: [], 
      currentNumbers: [], 
      isActive: false,
      maxPlayers: 6,
      isFull: false,
      waitingPlayers: 0
    },
    { 
      id: 3, 
      name: 'room C', 
      players: [], 
      currentNumbers: [], 
      isActive: false,
      maxPlayers: 6,
      isFull: false,
      waitingPlayers: 0
    }
  ]);

  useEffect(() => {
    // 模擬每日排行榜
    const today = new Date().toISOString().split('T')[0];
    const simulatedScores: BingoScore[] = [
      { deviceName: 'BingoMaster', score: 6, timestamp: Date.now() - 300000, date: today },
      { deviceName: 'LineHunter', score: 5, timestamp: Date.now() - 600000, date: today },
      { deviceName: 'NumberWiz', score: 4, timestamp: Date.now() - 900000, date: today },
      { deviceName: 'LuckyPlayer', score: 3, timestamp: Date.now() - 1200000, date: today },
    ];
    setLeaderboard(simulatedScores);
  }, []);

  const generateBingoCard = (): BingoCardType => {
    const numbers: number[] = [];
    const used = new Set<number>();
    
    // 生成25個不重複的1-60號碼
    while (numbers.length < 25) {
      const num = Math.floor(Math.random() * 60) + 1;
      if (!used.has(num)) {
        used.add(num);
        numbers.push(num);
      }
    }
    
    return {
      numbers,
      marked: new Array(25).fill(false)
    };
  };

  const generateRoomPlayers = () => {
    const playerNames = [
      'BingoKing', 'LuckyStrike', 'NumberHunter', 'LineChaser', 'BingoMaster'
    ];
    const players = playerNames.slice(0, Math.floor(Math.random() * 4) + 2).map(name => ({
      name,
      completedLines: 0,
      hasWon: false
    }));
    
    // 加入自己 - 使用傳入的 deviceName
    players.push({
      name: deviceName,
      completedLines: 0,
      hasWon: false
    });
    
    return players;
  };

  const checkRoomStatus = (roomId: number) => {
    const room = rooms.find(r => r.id === roomId);
    if (!room) return;

    const isFull = room.players.length >= room.maxPlayers;
    const waitingCount = Math.max(0, room.waitingPlayers);

    if (isFull) {
      toast.info(t('room_full'), {
        description: t('room_full_desc')
      });
      return false;
    }

    if (waitingCount > 0) {
      const position = waitingCount + 1;
      toast.info(t('waiting_for_room'), {
        description: t('waiting_position', { position })
      });
      return false;
    }

    return true;
  };

  const joinRoom = (roomId: number) => {
    const room = rooms.find(r => r.id === roomId);
    if (!room) return;

    // 檢查房間狀態
    if (!checkRoomStatus(roomId)) {
      // 如果房間已滿，加入等待列表
      if (room.isFull) {
        setIsWaiting(true);
        setWaitingPosition(room.waitingPlayers + 1);
        room.waitingPlayers++;
        
        // 模擬等待過程
        const checkInterval = setInterval(() => {
          if (room.players.length < room.maxPlayers) {
            clearInterval(checkInterval);
            setIsWaiting(false);
            setWaitingPosition(null);
            room.waitingPlayers--;
            actuallyJoinRoom(roomId);
          }
        }, 5000); // 每5秒檢查一次

        return;
      }
      return;
    }

    actuallyJoinRoom(roomId);
  };

  const actuallyJoinRoom = (roomId: number) => {
    setCurrentRoom(roomId);
    setBingoCard(generateBingoCard());
    setDrawnNumbers([]);
    setCompletedLines(0);
    setGameWon(false);
    setGameEnded(false);
    setRoomPlayers(generateRoomPlayers());
    setRoomChatMessages([]);
    setNewChatMessage('');
    
    // 更新房間狀態
    const room = rooms.find(r => r.id === roomId);
    if (room) {
      room.players.push(deviceName);
      room.isFull = room.players.length >= room.maxPlayers;
    }
    
    // 模擬號碼抽取
    setTimeout(() => {
      startDrawingNumbers();
    }, 2000);
  };

  const startDrawingNumbers = () => {
    const drawInterval = setInterval(() => {
      if (gameEnded) {
        clearInterval(drawInterval);
        return;
      }

      const availableNumbers = Array.from({length: 60}, (_, i) => i + 1)
        .filter(num => !drawnNumbers.includes(num));
      
      if (availableNumbers.length === 0) {
        clearInterval(drawInterval);
        return;
      }
      
      const newNumber = availableNumbers[Math.floor(Math.random() * availableNumbers.length)];
      setDrawnNumbers(prev => [...prev, newNumber]);
      
      simulateOtherPlayersProgress();
    }, 4000);
  };

  const simulateOtherPlayersProgress = () => {
    setRoomPlayers(prev => 
      prev.map(player => {
        if (player.name === deviceName || player.hasWon || gameEnded) return player;
        
        if (Math.random() < 0.3) {
          const newLines = player.completedLines + 1;
          const hasWon = newLines >= 6;
          
          if (newLines > player.completedLines) {
            toast.info(`${player.name} ${t('player_completed_lines')} ${newLines} ${t('lines')}!`, {
              description: hasWon ? t('player_won') : t('keep_going')
            });

            if (hasWon) {
              setGameEnded(true);
              const gameEndMessage: RoomChatMessage = {
                id: crypto.randomUUID(),
                message: `${player.name} ${t('game_end_message')}`,
                playerName: t('system_message'),
                timestamp: Date.now(),
                isOwn: false
              };
              setRoomChatMessages(prev => [gameEndMessage, ...prev]);
            }
          }
          
          return {
            ...player,
            completedLines: newLines,
            hasWon
          };
        }
        return player;
      })
    );
  };

  const markNumber = (index: number) => {
    if (!bingoCard || gameWon || gameEnded) return;
    
    const number = bingoCard.numbers[index];
    if (!drawnNumbers.includes(number) || bingoCard.marked[index]) return;
    
    const newMarked = [...bingoCard.marked];
    newMarked[index] = true;
    setBingoCard({ ...bingoCard, marked: newMarked });
    
    const lines = checkCompletedLines(newMarked);
    setCompletedLines(lines);
    
    setRoomPlayers(prev => 
      prev.map(player => 
        player.name === deviceName 
          ? { ...player, completedLines: lines, hasWon: lines >= 6 }
          : player
      )
    );
    
    if (lines >= 6 && !gameWon) {
      setGameWon(true);
      setGameEnded(true);
      updateLeaderboard(lines);
      
      const winMessage: RoomChatMessage = {
        id: crypto.randomUUID(),
        message: t('win_message'),
        playerName: t('system_message'),
        timestamp: Date.now(),
        isOwn: false
      };
      setRoomChatMessages(prev => [winMessage, ...prev]);
      
      toast.success(t('congratulations'), {
        description: t('completed_lines_count', { count: lines })
      });
    }
  };

  const checkCompletedLines = (marked: boolean[]): number => {
    let lines = 0;
    
    // 檢查橫線
    for (let row = 0; row < 5; row++) {
      if (marked.slice(row * 5, (row + 1) * 5).every(m => m)) {
        lines++;
      }
    }
    
    // 檢查直線
    for (let col = 0; col < 5; col++) {
      if ([0, 1, 2, 3, 4].every(row => marked[row * 5 + col])) {
        lines++;
      }
    }
    
    // 檢查對角線
    if ([0, 6, 12, 18, 24].every(i => marked[i])) {
      lines++;
    }
    if ([4, 8, 12, 16, 20].every(i => marked[i])) {
      lines++;
    }
    
    return lines;
  };

  const updateLeaderboard = (score: number) => {
    const today = new Date().toISOString().split('T')[0];
    const newScore: BingoScore = {
      deviceName,
      score,
      timestamp: Date.now(),
      date: today
    };
    
    const updatedLeaderboard = [...leaderboard, newScore]
      .filter(s => s.date === today)
      .sort((a, b) => b.score - a.score)
      .slice(0, 10);
      
    setLeaderboard(updatedLeaderboard);
  };

  const sendRoomChatMessage = () => {
    if (!newChatMessage.trim()) return;

    const message: RoomChatMessage = {
      id: crypto.randomUUID(),
      message: newChatMessage.trim(),
      playerName: deviceName,
      timestamp: Date.now(),
      isOwn: true
    };

    setRoomChatMessages(prev => [message, ...prev].slice(0, 30));
    setNewChatMessage('');

    // 修改模擬其他玩家的聊天回應
    const responses = [
      t('chat_response_1'),
      t('chat_response_2'),
      t('chat_response_3'),
      t('chat_response_4'),
      t('chat_response_5')
    ];
    
    const randomPlayer = roomPlayers.find(p => p.name !== deviceName);
    if (randomPlayer && Math.random() < 0.4) {
      const randomResponse = responses[Math.floor(Math.random() * responses.length)];
      const responseMessage: RoomChatMessage = {
        id: crypto.randomUUID(),
        message: randomResponse,
        playerName: randomPlayer.name,
        timestamp: Date.now(),
        isOwn: false
      };
      
      setRoomChatMessages(prev => [responseMessage, ...prev].slice(0, 30));
    }
  };

  const leaveRoom = () => {
    if (currentRoom) {
      const room = rooms.find(r => r.id === currentRoom);
      if (room) {
        room.players = room.players.filter(p => p !== deviceName);
        room.isFull = room.players.length >= room.maxPlayers;
      }
    }

    setCurrentRoom(null);
    setBingoCard(null);
    setDrawnNumbers([]);
    setCompletedLines(0);
    setGameWon(false);
    setGameEnded(false);
    setRoomPlayers([]);
    setRoomChatMessages([]);
    setNewChatMessage('');
    setIsWaiting(false);
    setWaitingPosition(null);
  };

  if (isWaiting && waitingPosition !== null) {
    return (
      <div className="space-y-6">
        <div className="p-4 bg-yellow-50 border border-yellow-200 rounded-lg text-center">
          <h3 className="text-lg font-semibold text-yellow-800 mb-2">
            {t('waiting_for_room')}
          </h3>
          <p className="text-sm text-yellow-700">
            {t('waiting_position', { position: waitingPosition })}
          </p>
          <div className="mt-4">
            <Button variant="outline" onClick={leaveRoom}>
              {t('cancel_waiting')}
            </Button>
          </div>
        </div>
      </div>
    );
  }

  if (currentRoom) {
    const room = rooms.find(r => r.id === currentRoom);
    return (
      <div className="space-y-6">
        {/* Game Header */}
        <div className="flex items-center justify-between">
          <h3 className="text-base font-semibold text-gray-900 text-left">
            {room?.name} - {t('bingo_game_room')}
            {gameEnded && ` (${t('game_ended_title')})`}
          </h3>
          <div className="text-sm text-gray-600">
            {t('completed_lines')}: {completedLines}/6 {gameWon && '🎉 ' + t('congratulations')}
          </div>
        </div>
        
        {/* Game Content */}
        <div className="space-y-4">
          {gameEnded && (
            <div className="p-3 bg-yellow-50 border border-yellow-200 rounded-lg text-center">
              <p className="text-sm text-yellow-800">
                {gameWon ? '🎉 ' + t('congratulations') : t('waiting_next_game')}
              </p>
            </div>
          )}
          <PlayerList players={roomPlayers} deviceName={deviceName} />
          <DrawnNumbers drawnNumbers={drawnNumbers} />
          
          {bingoCard && (
            <BingoCard
              bingoCard={bingoCard}
              drawnNumbers={drawnNumbers}
              onMarkNumber={markNumber}
              gameWon={gameWon}
            />
          )}

          <div className="text-center">
            <Button variant="outline" onClick={leaveRoom}>
              {t('leave_room')}
            </Button>
          </div>

          <RoomChat
            roomName={room?.name || ''}
            messages={roomChatMessages}
            newMessage={newChatMessage}
            setNewMessage={setNewChatMessage}
            onSendMessage={sendRoomChatMessage}
          />
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 直接顯示房間選擇器 */}
      <RoomSelector rooms={rooms} onJoinRoom={joinRoom} />
      
      {/* 其他內容 */}
      <GameRules />
      <Leaderboard leaderboard={leaderboard} />
    </div>
  );
};
