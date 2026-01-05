<?php

namespace App\Mail;

use App\Models\Trip;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Mail\Mailables\Attachment;

class TripReportMail extends Mailable
{
    use Queueable, SerializesModels;

    public $trip;
    protected $pdfData;

    /**
     * Create a new message instance.
     *
     * @param \App\Models\Trip $trip
     * @param string $pdfData Raw PDF data
     * @return void
     */
    public function __construct(Trip $trip, $pdfData)
    {
        $this->trip = $trip;
        $this->pdfData = $pdfData;
    }

    /**
     * Get the message envelope.
     *
     * @return \Illuminate\Mail\Mailables\Envelope
     */
    public function envelope()
    {
        return new Envelope(
            subject: 'Trip Report Details: #' . $this->trip->id,
        );
    }

    /**
     * Get the message content definition.
     *
     * @return \Illuminate\Mail\Mailables\Content
     */
    public function content()
    {
        // A simple blade view for the email body
        return new Content(
            view: 'emails.trip_report',
        );
    }

    /**
     * Get the attachments for the message.
     *
     * @return array
     */
    public function attachments()
    {
        return [
            // Attach the raw PDF data
            Attachment::fromData(fn () => $this->pdfData, 'Trip-Report-'.$this->trip->id.'.pdf')
                ->withMime('application/pdf'),
        ];
    }
}
