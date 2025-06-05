
import React from 'react';
import { Navigation } from 'lucide-react';

interface DirectionCompassProps {
  direction: 'N' | 'NE' | 'E' | 'SE' | 'S' | 'SW' | 'W' | 'NW';
  distance: number;
  className?: string;
}

const directionAngles = {
  N: 0,
  NE: 45,
  E: 90,
  SE: 135,
  S: 180,
  SW: 225,
  W: 270,
  NW: 315
};

const directionLabels = {
  N: '北',
  NE: '東北',
  E: '東',
  SE: '東南',
  S: '南',
  SW: '西南',
  W: '西',
  NW: '西北'
};

export const DirectionCompass: React.FC<DirectionCompassProps> = ({ 
  direction, 
  distance, 
  className = '' 
}) => {
  const angle = directionAngles[direction];
  const label = directionLabels[direction];
  
  const formatDistance = (dist: number) => {
    if (dist < 1000) {
      return `${dist}m`;
    } else {
      return `${(dist / 1000).toFixed(1)}km`;
    }
  };

  return (
    <div className={`flex items-center space-x-2 ${className}`}>
      <div className="relative w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center">
        <Navigation 
          className="w-4 h-4 text-blue-600" 
          style={{ transform: `rotate(${angle}deg)` }}
        />
      </div>
      <div className="text-sm">
        <div className="font-medium text-gray-900">{formatDistance(distance)}</div>
        <div className="text-xs text-gray-500">{label}方</div>
      </div>
    </div>
  );
};
