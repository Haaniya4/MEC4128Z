% Run both models and overlay the terminal voltage and current
out_a = sim('Quadcopter_2DoF_Model_7_a'); % battery model
out_b = sim('Quadcopter_2DoF_Model_7_bl');% ideal 12.6 V source

figure('Name', 'Battery model vs ideal source');
tiledlayout(2, 1, 'TileSpacing', 'compact');

nexttile; hold on; grid on
plot(outB.V_log.Time, squeeze(outB.V_log.Data), 'DisplayName', 'Battery model');
plot(outI.V_log.Time, squeeze(outI.V_log.Data), '--', 'DisplayName', 'Ideal 12.6 V');
yline(9.0, 'k:', '9.0 V cut-off', 'HandleVisibility', 'off');
ylabel('Terminal voltage U_L (V)'); legend('Location', 'best');

nexttile; hold on; grid on
plot(outB.I_log.Time, squeeze(outB.I_log.Data), 'DisplayName', 'Battery model');
plot(outI.I_log.Time, squeeze(outI.I_log.Data), '--', 'DisplayName', 'Ideal 12.6 V');
xlabel('Time (s)'); ylabel('Current I_L (A)'); legend('Location', 'best');

Charge (Ah) = 2.868/12.6 V
Final SOC   = 1 − Charge ÷ 0.55