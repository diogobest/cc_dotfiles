require 'rake'

desc 'Install Campus Code Dotfile in your machine'
task :install do
  puts 'Thank you for choose Campus Code Dotfiles (cc_dotfiles)'

  install_files(Dir.glob([
                           'aliases',
                           'tmux.conf',
                           'vimrc',
                           'zsh',
                           'zshenv',
                           'zshrc',
                           'bin',
                           'git/*',
                           'irb/*'
                         ]))

  install_config_files(Dir.glob(['hypr/*'])) if linux?

  # tmux >= 3.1 reads ~/.config/tmux/tmux.conf in preference to ~/.tmux.conf, and
  # nvim only ever reads ~/.config/nvim. Link both so a stale copy at the XDG path
  # can't shadow this repo.
  link_config('tmux.conf', 'tmux/tmux.conf')
  link_config('nvim', 'nvim')

  Rake::Task[:claude].invoke

  install_prereqs
  install_fonts
  install_zsh_syntax_highlighting
  tmux_copy_mode
  clone_tpm
  change_shell
  installation_message
end

desc 'Install Claude Code hooks (WorktreeCreate/WorktreeRemove) and the SSCROP per-worktree database'
task :claude do
  install_claude_hooks
  install_sscrop_worktree_db
end

private

CLAUDE_WORKTREE_HOOKS = {
  'WorktreeCreate' => { 'script' => 'worktree-create.sh', 'timeout' => 300,
                        'statusMessage' => 'Criando worktree e banco...' },
  'WorktreeRemove' => { 'script' => 'worktree-remove.sh', 'timeout' => 120 }
}.freeze

def dotfiles_root
  File.expand_path(__dir__)
end

# Links claude/hooks/* into ~/.claude/hooks and registers them in ~/.claude/settings.json,
# merging with whatever is already there (other hooks, permissions, model...).
def install_claude_hooks
  require 'json'

  hooks_dir = File.join(ENV['HOME'], '.claude', 'hooks')
  run_command %( mkdir -p "#{hooks_dir}" )
  Dir.glob(File.join(dotfiles_root, 'claude', 'hooks', '*')).each do |source|
    target = File.join(hooks_dir, File.basename(source))
    if File.exist?(target) && !File.symlink?(target)
      puts "Moving #{target} to #{target}.bkp"
      run_command %( mv "#{target}" "#{target}.bkp" )
    end
    run_command %( ln -nfs "#{source}" "#{target}" )
  end

  settings_path = File.join(ENV['HOME'], '.claude', 'settings.json')
  settings = File.exist?(settings_path) ? JSON.parse(File.read(settings_path)) : {}
  settings['hooks'] ||= {}
  CLAUDE_WORKTREE_HOOKS.each do |event, opts|
    hook = { 'type' => 'command', 'command' => "~/.claude/hooks/#{opts['script']}", 'timeout' => opts['timeout'] }
    hook['statusMessage'] = opts['statusMessage'] if opts['statusMessage']
    settings['hooks'][event] = [{ 'hooks' => [hook] }]
  end
  run_command %( cp "#{settings_path}" "#{settings_path}.bkp" ) if File.exist?(settings_path)
  File.write(settings_path, "#{JSON.pretty_generate(settings)}\n")
  puts "Registered #{CLAUDE_WORKTREE_HOOKS.keys.join(' and ')} in #{settings_path}"
rescue JSON::ParserError => e
  puts "Skipping Claude hooks: #{settings_path} is not valid JSON (#{e.message})"
end

# Per-worktree database for SSCROP: links worktree-db and post-checkout into the repo's
# .git/hooks (shared by every worktree). Skipped when the repo isn't cloned yet.
def install_sscrop_worktree_db
  repo = File.expand_path(ENV.fetch('SSCROP_DIR', '~/Documents/sscrop'))
  git_dir = File.join(repo, '.git')
  unless File.directory?(git_dir)
    puts "SSCROP not found at #{repo} — skipping worktree-db (rerun `rake claude` after cloning, or set SSCROP_DIR)"
    return
  end

  %w[worktree-db post-checkout].each do |name|
    source = File.join(dotfiles_root, 'claude', 'sscrop', name)
    target = File.join(git_dir, 'hooks', name)
    if File.exist?(target) && !File.symlink?(target)
      puts "Moving #{target} to #{target}.bkp"
      run_command %( mv "#{target}" "#{target}.bkp" )
    end
    run_command %( ln -nfs "#{source}" "#{target}" )
  end

  exclude = File.join(git_dir, 'info', 'exclude')
  current = File.exist?(exclude) ? File.read(exclude).lines.map(&:chomp) : []
  missing = %w[.env.development.local .env.test.local] - current
  File.open(exclude, 'a') { |f| missing.each { |line| f.puts line } } if missing.any?
  puts "SSCROP worktree-db installed in #{git_dir}/hooks"
end

def cc_dotfiles_folder
  '$HOME/.cc_dotfiles'
end

def change_shell
  puts 'You will change your default shell to zsh'
  run_command %{ chsh -s $(which zsh) }
end

def install_zsh_syntax_highlighting
  return if File.exist?("#{ENV['HOME']}/.zsh-syntax-highlighting")

  run_command %( git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh-syntax-highlighting )
end

def clone_tpm
  return if File.exist?("#{ENV['HOME']}/.tmux/plugins/tpm")

  run_command %(git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm)
end

def tmux_copy_mode
  folder = cc_dotfiles_folder
  run_command %( cp #{folder}/templates/copy_mode_mac.conf.tmp $HOME/.tmux_copy_mode.conf ) if macos?
  run_command %( cp #{folder}/templates/copy_mode_linux.conf.tmp $HOME/.tmux_copy_mode.conf ) if linux?
end

def install_files(files)
  files.each do |f|
    file_name = f.split('/').last
    source = "#{ENV['PWD']}/#{f}"
    file = "#{ENV['HOME']}/.#{file_name}"

    if File.exist?(file)
      puts "Moving #{file} to #{file}.bkp"
      run_command %( mv #{file} #{file}.bkp )
    end

    run_command %( ln -nfs "#{source}" "#{file}" )
  end
end

# Links files into ~/.config/<dir>/<file> instead of ~/.<file>, for apps that
# expect XDG config paths (e.g. hypr/input.lua for Hyprland/Omarchy).
def install_config_files(files)
  files.each do |f|
    source = "#{ENV['PWD']}/#{f}"
    target_dir = "#{ENV['HOME']}/.config/#{File.dirname(f)}"
    target = "#{target_dir}/#{File.basename(f)}"

    run_command %( mkdir -p #{target_dir} )

    if File.exist?(target) && !File.symlink?(target)
      puts "Moving #{target} to #{target}.bkp"
      run_command %( mv #{target} #{target}.bkp )
    end

    run_command %( ln -nfs "#{source}" "#{target}" )
  end
end

# Links a single file or directory into ~/.config/<target>, for apps that read
# XDG config paths rather than ~/.<name>.
def link_config(source_rel, target_rel)
  source = "#{ENV['PWD']}/#{source_rel}"
  target = "#{ENV['HOME']}/.config/#{target_rel}"

  run_command %( mkdir -p #{File.dirname(target)} )

  if File.exist?(target) && !File.symlink?(target)
    puts "Moving #{target} to #{target}.bkp"
    run_command %( mv #{target} #{target}.bkp )
  end

  run_command %( ln -nfs "#{source}" "#{target}" )
end

def install_fonts
  puts '======================================================'
  puts 'Installing patched fonts for Powerline/Lightline.'
  puts '======================================================'
  run_command %( cp -f $HOME/.cc_dotfiles/fonts/* $HOME/Library/Fonts ) if macos?
  run_command %( mkdir -p ~/.fonts && cp ~/.cc_dotfiles/fonts/* ~/.fonts && fc-cache -vf ~/.fonts ) if linux?
  puts
end

def run_command(cmd)
  puts "running #{cmd}"
  system cmd
rescue StandardError
  puts "Error running #{cmd}"
end

def macos?
  RUBY_PLATFORM.downcase.include?('darwin')
end

def linux?
  RUBY_PLATFORM.downcase.include?('linux')
end

def linux_message
  puts ''
  puts '- Change your terminal window to Run command as login shell and RESTART'
  puts ''
  puts "- You can find more information about this on \r
https://github.com/rvm/ubuntu_rvm"
end

def installation_message
  puts ''
  puts ''
  puts '======================================================================='
  puts 'Thank you!'
  puts ''
  puts ''
  linux_message if linux?
  puts '======================================================================='
end

def install_prereqs
  run_command %( $HOME/.cc_dotfiles/mac.sh ) if macos?
  run_command %( $HOME/.cc_dotfiles/ubuntu.sh ) if linux?
end
