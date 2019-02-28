class User < ApplicationRecord
	require "facebook/messenger"

	include Facebook::Messenger

	has_many :flow_entry

	# @TODO Stop shouldnt be sendind message
	def stop_flow_test str = nil
		self.update_attribute(:flow_testing, false)
		if str.nil?
			send_text(self.psid, "Fin du test")
		end
	end

	def start_flow_test
		# Define random new Time
		tableau_intervalles = []
		total = 0
		current_time = Time.now
		begin
			nouveau_temps = (3600 + rand(5400))
			current_time = current_time + nouveau_temps
			total = total + nouveau_temps
			tableau_intervalles << current_time.iso8601
		end until total > 80000

		intervalles = ""
		tableau_intervalles.each do |i|
			intervalles << i
			intervalles << " "
		end

		# Then change user attributes in db
		current_user = self
		current_user.update_attributes(:flow_test_intervals => intervalles, :flow_testing => true)
	end

	def received_test
		send_text(self.psid, "J'ai bien recu ton echantillon de vie, merci.")
	end

	def flow_test_bip
		send_text(self.psid, "C'est l'heure des mesures ! https://alfredcorp.typeform.com/to/hwJrHr?id=#{self.private_id}")
	end

	# @TODO Bad method name
	def end_of_day(message)
		send_text(self.psid, "Bonne nuit")
	end

	private

	def send_text(psid, text)
		begin
			Bot.deliver({
				recipient: {"id" => psid},
				message: {
				  text: text
				}
			}, access_token: ENV["ACCESS_TOKEN"])
		rescue
			# If message not delivered (a cause can be that the user blocked Alfred)
			self.stop_flow_test(0)
		end
	end
end
