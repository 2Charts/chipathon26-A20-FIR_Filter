module tb_dump;
  initial begin
    $dumpfile("waveform_sys.vcd");
    // Just a dummy to prevent errors if we don't compile it, but let's just parse the vcd.
  end
endmodule
