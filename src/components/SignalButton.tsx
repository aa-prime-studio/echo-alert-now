
import React from 'react';
import { AlertTriangle, Heart, Package, Shield } from 'lucide-react';
import { Button } from '@/components/ui/button';

interface SignalButtonProps {
  type: 'safe' | 'supplies' | 'medical' | 'danger';
  onSend: (type: 'safe' | 'supplies' | 'medical' | 'danger') => void;
  disabled?: boolean;
}

const signalConfig = {
  safe: {
    label: '我安全',
    description: 'I\'m Safe',
    color: 'text-white',
    bgColor: 'bg-[#263eea] hover:bg-[#1d32d4]',
    icon: Shield
  },
  supplies: {
    label: '需要物資',
    description: 'Need Supplies',
    color: 'text-white',
    bgColor: 'bg-[#b199ea] hover:bg-[#a085e6]',
    icon: Package
  },
  medical: {
    label: '需要醫療',
    description: 'Need Medical',
    color: 'text-white',
    bgColor: 'bg-[#ff5662] hover:bg-[#ff4553]',
    icon: Heart
  },
  danger: {
    label: '危險警告',
    description: 'Danger Warning',
    color: 'text-black',
    bgColor: 'bg-[#fec91b] hover:bg-[#fdc107]',
    icon: AlertTriangle
  }
};

export const SignalButton: React.FC<SignalButtonProps> = ({ type, onSend, disabled }) => {
  const config = signalConfig[type];
  const Icon = config.icon;

  return (
    <Button
      onClick={() => onSend(type)}
      disabled={disabled}
      className={`h-32 w-full ${config.bgColor} ${config.color} flex flex-col items-center justify-center space-y-2 text-lg font-semibold transition-all duration-200 transform active:scale-95`}
    >
      <Icon className="w-8 h-8" />
      <div className="text-center">
        <div>{config.label}</div>
        <div className="text-sm opacity-90">{config.description}</div>
      </div>
    </Button>
  );
};
