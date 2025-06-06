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

interface GameRoomProps {
  deviceName: string;
}

export const GameRoom: React.FC<GameRoomProps> = ({ deviceName }) => {
  const [currentRoom, setCurrentRoom] = useState<number | null>(null);
  const [leaderboard, setLeaderboard] = useState<BingoScore[]>([]);
  const [bingoCard, setBingoCard] = useState<BingoCardType | null>(null);
  const [drawnNumbers, setDrawnNumbers] = useState<number[]>([]);
  const [completedLines, setCompletedLines] = useState(0);
  const [gameWon, setGameWon] = useState(false);
  const [roomPlayers, setRoomPlayers] = useState<RoomPlayer[]>([]);
  const [roomChatMessages, setRoomChatMessages] = useState<RoomChatMessage[]>([]);
  const [newChatMessage, setNewChatMessage] = useState('');

  // 3個賓果房間
  const [rooms] = useState<BingoRoom[]>([
    { id: 1, name: 'room A', players: [], currentNumbers: [], isActive: false },
    { id: 2, name: 'room B', players: [], currentNumbers: [], isActive: false },
    { id: 3, name: 'room C', players: [], currentNumbers: [], isActive: false }
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

  const joinRoom = (roomId: number) => {
    setCurrentRoom(roomId);
    setBingoCard(generateBingoCard());
    setDrawnNumbers([]);
    setCompletedLines(0);
    setGameWon(false);
    setRoomPlayers(generateRoomPlayers());
    setRoomChatMessages([]);
    setNewChatMessage('');
    
    // 模擬號碼抽取
    setTimeout(() => {
      startDrawingNumbers();
    }, 2000);
  };

  const startDrawingNumbers = () => {
    const drawInterval = setInterval(() => {
      const availableNumbers = Array.from({length: 60}, (_, i) => i + 1)
        .filter(num => !drawnNumbers.includes(num));
      
      if (availableNumbers.length === 0) {
        clearInterval(drawInterval);
        return;
      }
      
      const newNumber = availableNumbers[Math.floor(Math.random() * availableNumbers.length)];
      setDrawnNumbers(prev => [...prev, newNumber]);
      
      // 模擬其他玩家的進度
      simulateOtherPlayersProgress();
    }, 15000);

    // 模擬遊戲結束
    setTimeout(() => {
      clearInterval(drawInterval);
    }, 180000);
  };

  const simulateOtherPlayersProgress = () => {
    setRoomPlayers(prev => 
      prev.map(player => {
        if (player.name === deviceName || player.hasWon) return player;
        
        // 隨機機會增加線數
        if (Math.random() < 0.3) {
          const newLines = player.completedLines + 1;
          const hasWon = newLines >= 6;
          
          if (newLines > player.completedLines) {
            toast.info(`${player.name} 完成了 ${newLines} 條線！`, {
              description: hasWon ? '🎉 獲勝了！' : '繼續加油！'
            });
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
    if (!bingoCard || gameWon) return;
    
    const number = bingoCard.numbers[index];
    if (!drawnNumbers.includes(number) || bingoCard.marked[index]) return;
    
    const newMarked = [...bingoCard.marked];
    newMarked[index] = true;
    setBingoCard({ ...bingoCard, marked: newMarked });
    
    // 檢查完成的線
    const lines = checkCompletedLines(newMarked);
    setCompletedLines(lines);
    
    // 更新自己在房間玩家列表中的進度
    setRoomPlayers(prev => 
      prev.map(player => 
        player.name === deviceName 
          ? { ...player, completedLines: lines, hasWon: lines >= 6 }
          : player
      )
    );
    
    if (lines >= 6 && !gameWon) {
      setGameWon(true);
      updateLeaderboard(lines);
      toast.success('🎉 恭喜獲勝！', {
        description: `完成了 ${lines} 條線！`
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

    // 模擬其他玩家的聊天回應
    setTimeout(() => {
      const responses = [
        '加油！',
        '好運氣！',
        '快中了！',
        '我也差一條線',
        '這個號碼不錯'
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
    }, 1000 + Math.random() * 2000);
  };

  const leaveRoom = () => {
    setCurrentRoom(null);
    setBingoCard(null);
    setDrawnNumbers([]);
    setCompletedLines(0);
    setGameWon(false);
    setRoomPlayers([]);
    setRoomChatMessages([]);
    setNewChatMessage('');
  };

  if (currentRoom) {
    const room = rooms.find(r => r.id === currentRoom);
    return (
      <div className="space-y-6">
        {/* Game Header */}
        <div className="flex items-center justify-between">
          <h3 className="text-xl font-semibold text-gray-900 text-left">{room?.name} - 賓果遊戲</h3>
          <div className="text-sm text-gray-600">
            完成線數: {completedLines}/6 {gameWon && '🎉 獲勝!'}
          </div>
        </div>
        
        {/* Game Content */}
        <div className="space-y-4">
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
              離開房間
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
      {/* Header */}
      <div className="flex items-center space-x-2">
        <h3 className="text-xl font-semibold text-gray-900 text-left">賓果遊戲室</h3>
      </div>
      
      {/* Game Selection Content */}
      <div className="space-y-4">
        <RoomSelector rooms={rooms} onJoinRoom={joinRoom} />
        <GameRules />
        <Leaderboard leaderboard={leaderboard} />
      </div>
    </div>
  );
};
