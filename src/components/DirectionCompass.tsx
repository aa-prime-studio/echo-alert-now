
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
  N: '北方',
  NE: '東北方',
  E: '東方',
  SE: '東南方',
  S: '南方',
  SW: '西南方',
  W: '西方',
  NW: '西北方'
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
    <div className={`flex items-center justify-end space-x-2 ${className}`}>
      <div className="text-right">
        <div className="text-lg font-semibold text-gray-900">{formatDistance(distance)}</div>
        <div className="text-sm text-gray-500">{label}</div>
      </div>
      <div className="relative w-6 h-6 bg-yellow-400 rounded-full flex items-center justify-center">
        <Navigation 
          className="w-3 h-3 text-black" 
          style={{ transform: `rotate(${angle}deg)` }}
        />
      </div>
    </div>
  );
};
