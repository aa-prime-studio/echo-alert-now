import React, { useState, useEffect } from 'react';
import { Gamepad2, Trophy, Users, Star, RotateCcw, Grid3X3 } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface BingoScore {
  deviceName: string;
  score: number;
  timestamp: number;
  date: string;
}

interface BingoRoom {
  id: number;
  name: string;
  players: string[];
  currentNumbers: number[];
  isActive: boolean;
}

interface BingoCard {
  numbers: number[];
  marked: boolean[];
}

export const GameRoom: React.FC = () => {
  const [currentRoom, setCurrentRoom] = useState<number | null>(null);
  const [leaderboard, setLeaderboard] = useState<BingoScore[]>([]);
  const [deviceName] = useState(`Player-${Math.random().toString(36).substr(2, 4)}`);
  const [bingoCard, setBingoCard] = useState<BingoCard | null>(null);
  const [drawnNumbers, setDrawnNumbers] = useState<number[]>([]);
  const [completedLines, setCompletedLines] = useState(0);
  const [gameWon, setGameWon] = useState(false);

  // 3個賓果房間
  const [rooms] = useState<BingoRoom[]>([
    { id: 1, name: '星光大廳', players: [], currentNumbers: [], isActive: false },
    { id: 2, name: '幸運殿堂', players: [], currentNumbers: [], isActive: false },
    { id: 3, name: '王者競技場', players: [], currentNumbers: [], isActive: false }
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

  const generateBingoCard = (): BingoCard => {
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

  const joinRoom = (roomId: number) => {
    setCurrentRoom(roomId);
    setBingoCard(generateBingoCard());
    setDrawnNumbers([]);
    setCompletedLines(0);
    setGameWon(false);
    
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
    }, 3000); // 每3秒抽一個號碼

    // 模擬遊戲結束
    setTimeout(() => {
      clearInterval(drawInterval);
    }, 60000); // 1分鐘後結束
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
    
    if (lines >= 6) {
      setGameWon(true);
      updateLeaderboard(lines);
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
      .filter(s => s.date === today) // 只保留今天的記錄
      .sort((a, b) => b.score - a.score)
      .slice(0, 10);
      
    setLeaderboard(updatedLeaderboard);
  };

  const leaveRoom = () => {
    setCurrentRoom(null);
    setBingoCard(null);
    setDrawnNumbers([]);
    setCompletedLines(0);
    setGameWon(false);
  };

  if (currentRoom) {
    const room = rooms.find(r => r.id === currentRoom);
    return (
      <div className="bg-white rounded-lg shadow p-6 h-full flex flex-col">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-gray-900">{room?.name} - 賓果遊戲</h3>
          <div className="text-sm text-gray-600">
            完成線數: {completedLines}/6 {gameWon && '🎉 獲勝!'}
          </div>
        </div>
        
        {/* 抽取號碼顯示 */}
        <div className="mb-4 p-3 bg-blue-50 rounded-lg">
          <div className="text-sm text-blue-800 mb-2">已抽取號碼:</div>
          <div className="flex flex-wrap gap-1">
            {drawnNumbers.slice(-10).map((num, index) => (
              <span key={index} className={`px-2 py-1 rounded text-xs font-bold ${
                index === drawnNumbers.slice(-10).length - 1 
                  ? 'bg-red-500 text-white' 
                  : 'bg-blue-200 text-blue-800'
              }`}>
                {num}
              </span>
            ))}
          </div>
          {drawnNumbers.length > 0 && (
            <div className="text-xs text-blue-600 mt-1">
              最新號碼: {drawnNumbers[drawnNumbers.length - 1]}
            </div>
          )}
        </div>
        
        {/* 賓果卡片 */}
        {bingoCard && (
          <div className="flex-1 flex flex-col items-center">
            <div className="grid grid-cols-5 gap-1 mb-4 max-w-xs">
              {bingoCard.numbers.map((number, index) => (
                <button
                  key={index}
                  onClick={() => markNumber(index)}
                  disabled={!drawnNumbers.includes(number) || bingoCard.marked[index]}
                  className={`w-12 h-12 text-sm font-bold rounded border-2 ${
                    bingoCard.marked[index]
                      ? 'bg-green-500 text-white border-green-600'
                      : drawnNumbers.includes(number)
                        ? 'bg-yellow-200 text-yellow-800 border-yellow-400 hover:bg-yellow-300'
                        : 'bg-gray-100 text-gray-600 border-gray-300'
                  }`}
                >
                  {number}
                </button>
              ))}
            </div>
            
            <div className="text-center space-y-2">
              <p className="text-sm text-gray-600">
                點擊已抽取的號碼來標記
              </p>
              <Button variant="outline" onClick={leaveRoom}>
                離開房間
              </Button>
            </div>
          </div>
        )}
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow h-full flex flex-col">
      <div className="p-4 border-b flex-shrink-0">
        <div className="flex items-center space-x-2">
          <Grid3X3 className="w-5 h-5 text-purple-600" />
          <h3 className="font-semibold text-gray-900">賓果遊戲室</h3>
        </div>
      </div>
      
      <div className="flex-1 p-4 space-y-4 overflow-y-auto">
        {/* 房間選擇 */}
        <div>
          <h4 className="text-sm font-medium text-gray-900 mb-3">選擇房間 (每房間6位玩家)</h4>
          <div className="grid grid-cols-1 gap-3">
            {rooms.map((room) => (
              <Button
                key={room.id}
                onClick={() => joinRoom(room.id)}
                className="h-16 bg-purple-500 hover:bg-purple-600 text-white flex flex-col items-center justify-center"
              >
                <span className="text-lg font-bold">{room.name}</span>
                <span className="text-sm opacity-90">
                  {Math.floor(Math.random() * 6) + 1}/6 玩家
                </span>
              </Button>
            ))}
          </div>
        </div>
        
        <div className="text-center text-sm text-gray-600 bg-gray-50 p-3 rounded-lg">
          <p className="font-medium">遊戲規則:</p>
          <p>• 號碼範圍: 1-60</p>
          <p>• 目標: 先完成6條線獲勝</p>
          <p>• 每日排行榜更新</p>
        </div>
        
        {/* 今日排行榜 */}
        {leaderboard.length > 0 && (
          <div>
            <div className="flex items-center space-x-2 mb-3">
              <Trophy className="w-4 h-4 text-yellow-600" />
              <h4 className="text-sm font-medium text-gray-900">今日排行榜</h4>
            </div>
            <div className="space-y-2">
              {leaderboard.slice(0, 5).map((score, index) => (
                <div key={`${score.deviceName}-${score.timestamp}`} className="flex items-center justify-between text-sm">
                  <div className="flex items-center space-x-2">
                    <span className={`w-5 h-5 rounded-full flex items-center justify-center text-xs font-bold ${
                      index === 0 ? 'bg-yellow-100 text-yellow-800' :
                      index === 1 ? 'bg-gray-100 text-gray-700' :
                      index === 2 ? 'bg-orange-100 text-orange-700' :
                      'bg-blue-50 text-blue-600'
                    }`}>
                      {index + 1}
                    </span>
                    <span className="text-gray-900">{score.deviceName}</span>
                  </div>
                  <span className="font-medium text-gray-700">{score.score}線</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
