
import React, { useState, useEffect } from 'react';
import { Gamepad2, Trophy, Users, Star, RotateCcw } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface GameScore {
  deviceName: string;
  score: number;
  timestamp: number;
}

export const GameRoom: React.FC = () => {
  const [currentGame, setCurrentGame] = useState<'memory' | 'reaction' | null>(null);
  const [gameScore, setGameScore] = useState(0);
  const [leaderboard, setLeaderboard] = useState<GameScore[]>([]);
  const [deviceName] = useState(`Player-${Math.random().toString(36).substr(2, 4)}`);

  // 記憶遊戲狀態
  const [memorySequence, setMemorySequence] = useState<number[]>([]);
  const [playerSequence, setPlayerSequence] = useState<number[]>([]);
  const [showingSequence, setShowingSequence] = useState(false);
  const [gameLevel, setGameLevel] = useState(1);

  // 反應遊戲狀態
  const [reactionStart, setReactionStart] = useState<number>(0);
  const [reactionWaiting, setReactionWaiting] = useState(false);
  const [reactionResults, setReactionResults] = useState<number[]>([]);

  useEffect(() => {
    // 模擬其他玩家分數
    const simulatedScores: GameScore[] = [
      { deviceName: 'SpeedRunner', score: 1250, timestamp: Date.now() - 300000 },
      { deviceName: 'MemoryMaster', score: 980, timestamp: Date.now() - 600000 },
      { deviceName: 'QuickFinger', score: 760, timestamp: Date.now() - 900000 },
    ];
    setLeaderboard(simulatedScores);
  }, []);

  const startMemoryGame = () => {
    setCurrentGame('memory');
    setGameScore(0);
    setGameLevel(1);
    setMemorySequence([]);
    setPlayerSequence([]);
    generateNewSequence();
  };

  const generateNewSequence = () => {
    const newNumber = Math.floor(Math.random() * 4) + 1;
    const newSequence = [...memorySequence, newNumber];
    setMemorySequence(newSequence);
    setPlayerSequence([]);
    setShowingSequence(true);
    
    // 顯示序列
    setTimeout(() => {
      setShowingSequence(false);
    }, newSequence.length * 600 + 500);
  };

  const handleMemoryClick = (number: number) => {
    if (showingSequence) return;
    
    const newPlayerSequence = [...playerSequence, number];
    setPlayerSequence(newPlayerSequence);
    
    // 檢查是否正確
    if (newPlayerSequence[newPlayerSequence.length - 1] !== memorySequence[newPlayerSequence.length - 1]) {
      // 遊戲結束
      endMemoryGame();
    } else if (newPlayerSequence.length === memorySequence.length) {
      // 這關過了
      setGameScore(prev => prev + gameLevel * 10);
      setGameLevel(prev => prev + 1);
      setTimeout(() => {
        generateNewSequence();
      }, 1000);
    }
  };

  const endMemoryGame = () => {
    updateLeaderboard(gameScore);
    setCurrentGame(null);
  };

  const startReactionGame = () => {
    setCurrentGame('reaction');
    setReactionResults([]);
    startReactionRound();
  };

  const startReactionRound = () => {
    setReactionWaiting(true);
    const delay = Math.random() * 3000 + 1000; // 1-4秒隨機延遲
    
    setTimeout(() => {
      setReactionStart(Date.now());
      setReactionWaiting(false);
    }, delay);
  };

  const handleReactionClick = () => {
    if (reactionWaiting) {
      // 太早按了
      setReactionResults([]);
      setCurrentGame(null);
      return;
    }
    
    if (reactionStart === 0) return;
    
    const reactionTime = Date.now() - reactionStart;
    const newResults = [...reactionResults, reactionTime];
    setReactionResults(newResults);
    
    if (newResults.length >= 5) {
      // 遊戲結束，計算平均反應時間
      const avgTime = newResults.reduce((a, b) => a + b, 0) / newResults.length;
      const score = Math.max(0, 1000 - Math.floor(avgTime));
      updateLeaderboard(score);
      setCurrentGame(null);
    } else {
      setReactionStart(0);
      setTimeout(() => {
        startReactionRound();
      }, 1000);
    }
  };

  const updateLeaderboard = (score: number) => {
    const newScore: GameScore = {
      deviceName,
      score,
      timestamp: Date.now()
    };
    
    const updatedLeaderboard = [...leaderboard, newScore]
      .sort((a, b) => b.score - a.score)
      .slice(0, 10); // 只保留前10名
      
    setLeaderboard(updatedLeaderboard);
  };

  if (currentGame === 'memory') {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-gray-900">記憶遊戲</h3>
          <div className="text-sm text-gray-600">
            關卡: {gameLevel} | 分數: {gameScore}
          </div>
        </div>
        
        <div className="grid grid-cols-2 gap-2 mb-4">
          {[1, 2, 3, 4].map((num) => (
            <Button
              key={num}
              onClick={() => handleMemoryClick(num)}
              disabled={showingSequence}
              className={`h-16 text-lg font-bold ${
                showingSequence && memorySequence.includes(num) 
                  ? 'bg-blue-500 text-white' 
                  : 'bg-gray-200 text-gray-800 hover:bg-gray-300'
              }`}
            >
              {num}
            </Button>
          ))}
        </div>
        
        <div className="text-center">
          <p className="text-sm text-gray-600 mb-2">
            {showingSequence ? '記住順序...' : '重複剛才的順序'}
          </p>
          <Button variant="outline" onClick={() => setCurrentGame(null)}>
            結束遊戲
          </Button>
        </div>
      </div>
    );
  }

  if (currentGame === 'reaction') {
    return (
      <div className="bg-white rounded-lg shadow p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="font-semibold text-gray-900">反應力測試</h3>
          <div className="text-sm text-gray-600">
            第 {reactionResults.length + 1}/5 次
          </div>
        </div>
        
        <div className="text-center mb-6">
          <Button
            onClick={handleReactionClick}
            disabled={reactionStart === 0 && !reactionWaiting}
            className={`w-full h-32 text-xl font-bold ${
              reactionWaiting 
                ? 'bg-red-500 hover:bg-red-600 text-white' 
                : reactionStart > 0 
                  ? 'bg-green-500 hover:bg-green-600 text-white'
                  : 'bg-gray-300 text-gray-600'
            }`}
          >
            {reactionWaiting 
              ? '等待...' 
              : reactionStart > 0 
                ? '現在按！' 
                : '準備開始'
            }
          </Button>
        </div>
        
        {reactionResults.length > 0 && (
          <div className="mb-4">
            <h4 className="text-sm font-medium mb-2">反應時間:</h4>
            <div className="flex flex-wrap gap-1">
              {reactionResults.map((time, index) => (
                <span key={index} className="text-xs bg-gray-100 px-2 py-1 rounded">
                  {time}ms
                </span>
              ))}
            </div>
          </div>
        )}
        
        <div className="text-center">
          <Button variant="outline" onClick={() => setCurrentGame(null)}>
            結束遊戲
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-white rounded-lg shadow">
      <div className="p-4 border-b">
        <div className="flex items-center space-x-2">
          <Gamepad2 className="w-5 h-5 text-purple-600" />
          <h3 className="font-semibold text-gray-900">遊戲室</h3>
        </div>
      </div>
      
      <div className="p-4 space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <Button
            onClick={startMemoryGame}
            className="h-20 bg-blue-500 hover:bg-blue-600 text-white flex flex-col items-center justify-center"
          >
            <Star className="w-6 h-6 mb-1" />
            <span className="text-sm">記憶遊戲</span>
          </Button>
          
          <Button
            onClick={startReactionGame}
            className="h-20 bg-green-500 hover:bg-green-600 text-white flex flex-col items-center justify-center"
          >
            <RotateCcw className="w-6 h-6 mb-1" />
            <span className="text-sm">反應力測試</span>
          </Button>
        </div>
        
        {leaderboard.length > 0 && (
          <div>
            <div className="flex items-center space-x-2 mb-3">
              <Trophy className="w-4 h-4 text-yellow-600" />
              <h4 className="text-sm font-medium text-gray-900">排行榜</h4>
            </div>
            <div className="space-y-2 max-h-32 overflow-y-auto">
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
                  <span className="font-medium text-gray-700">{score.score}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
