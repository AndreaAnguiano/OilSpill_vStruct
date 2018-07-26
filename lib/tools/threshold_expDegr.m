% [dailyDecayRates,thresholds] = threshold_expDegr(exp_deg_Percentage,exp_deg_Percentage_Days,time_step)
%
% exp_deg_Percentage = Percentage of oil to be removed on the days
%                      indicated in days_percentage_decay.
%
% exp_deg_Days       = Day for each oil class to which the indicated oil
%                      percentage will be removed.
%
% time_step          = The time step in hours of the Lagrangian model.
%
% dailyDecayRates    = Dacay rate in the exponential degradation equation
%                      considering that time (t) is in days.
%
% The output (thresholds) is used by oilDegradation.m in order to produce
% exponential degradation of particles. A uniform random number from 0 to 1
% is generated for each particle, and if it results higher than the
% threshold value, the particle is removed.
%
% Explanation
%
%   The exponential degradation equation is:
%
%                         C(t) = C0 * e^(-kt)
%
%      Where: t    = time
%             C(t) = concentration at time t
%             C0   = Initial concentration
%             k    = Instant decay rate
%
%   If we want the concentration to fall by 95% at time t then:
%
%                         C(t) = C0 * e^(-kt)
%
%                         C(t) = C0 * 0.05
%
%   So:                e^(-kt) = 0.05
%
%   Finding k:             -kt =  ln(0.05)
%
%                            k = -ln(0.05)/t
%
%   The constant fraction that survives from one day to the next is the threshold:
%
%                  C(t)/C(t-1) = threshold
%
%   Considering that:  C(t)/C0 = e^(-kt)
%
%                      C(1)/C0 = e^(-k) = threshold
%
function [threshold_expDeg,dailyDecayRates]  = threshold_expDegr(exp_deg_Percentage,exp_deg_Days,time_step)
% Compute daily decay rates
dailyDecayRates = -log(1-exp_deg_Percentage/100)./exp_deg_Days;
% Convert days_percent_decay to hours
hrs_percent_decay  = exp_deg_Days.*24;
% Adjust hrs_percent_decay to the time_step
time_percent_decay = hrs_percent_decay./time_step;
% Compute instant decay rates (k)
k = -log(1-exp_deg_Percentage/100)./time_percent_decay;
% Compute thresholds
threshold_expDeg = exp(-k);
end