require 'open3'

class Shell
  extend ElMixin

  CODE_SAMPLES = %q[
    # Run OS commands
    - in shell (asynchronously): Shell.run("ls", :dir => "/tmp")
    - Synchronously: Shell.run("ls", :dir => "/etc", :sync => true)
  ]

  # Run the command in a shell
  def self.run command, options={}
    #dir=nil, sync=nil, buffer_name=nil
    dir = options[:dir]
    sync = options[:sync]
    buffer = options[:buffer]
    reuse_buffer = options[:reuse_buffer]

    # Nil out dir if blank
    dir = nil if dir && dir.length == 0

    if dir
      dir = Bookmarks.expand(dir)
      # If relative dir, make current dir be on end of current
      dir = "#{elvar.default_directory}/#{dir}" unless dir =~ /^\//
      dir.gsub!(/\/\/+/, '/')

      # If file, but not dir, try backing up to the dir
      if File.exists?(dir) && ! File.directory?(dir)
        dir.sub!(/[^\/]+$/, '')
      end

      # If dir exists, continue
      if File.directory?(dir)
        # Put slash on end if not there
        dir = "#{dir}/" unless dir =~ /\/$/
      else  # Otherwise, exit
        return puts("#{dir} is not a dir")
      end
    else
      dir = elvar.default_directory
    end

    if sync
      stdin, stdout, stderr = Open3.popen3(". ~/.profile;cd #{dir};#{command}")
      result = ""
      result << stdout.readlines.join('')
      result << stderr.readlines.join('')
      return result

    else
      if View.in_bar? and ! options[:dont_leave_bar]
        View.to_after_bar
      end
      buffer ||= "*shell*"

      buffer = generate_new_buffer(buffer) unless reuse_buffer
      View.to_buffer buffer
      erase_buffer if reuse_buffer
      elvar.default_directory = dir if dir
      shell current_buffer
      Move.bottom
      if command  # If nil, just open shell
        insert command
        Shell.enter
        #comint_send_input
      end
    end
  end

  def self.open
    ControlLock.disable
    dir = elvar.default_directory
    switch_to_buffer generate_new_buffer("*shell*")
    elvar.default_directory = dir
    shell current_buffer
  end

  def self.enter
    #command_execute
    comint_send_input
  end

  def self.shell?
    View.mode == :shell_mode
  end

  def self.do_last_command
    erase_buffer
    comint_previous_input(1)
    comint_send_input
  end

  # Mapped to !! or ! in LineLauncher
  def self.launch options={}
    line = Line.without_label
    # If indented, check whether code tree, extracting if yes
    if Line.value =~ /^\s+!/
      orig = View.cursor
      # - of previous line
      path = TreeLs.construct_path(:list => true)
      if TreeLs.is_tree_ls_path(path)
        path.pop
        dir = path.join('')
      end
      View.to orig
    end
    line =~ / *(.*?)!+(.+)/
    dir ||= $1
    command = $2
    if options[:sync]
      output = Shell.run command, :dir => dir, :sync => true
      # Add linebreak if blank
      output.sub!(/\A\z/, "\n")
      output.gsub!(/^/, '!')
      TreeLs.indent(output)
      TreeLs.insert_quoted_and_search output
    else
      View.handle_bar
      Shell.run command, :dir => dir
    end
  end

end
